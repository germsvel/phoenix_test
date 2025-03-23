defmodule PhoenixTest.LiveViewTimeoutTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias PhoenixTest.Live
  alias PhoenixTest.LiveViewTimeout
  alias PhoenixTest.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def render_html(pid) do
      GenServer.call(pid, :render_html)
    end

    def redirect(pid) do
      GenServer.call(pid, :redirect)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:phoenix, :ping}, _from, state) do
      {:reply, :ok, state}
    end

    def handle_call(:render_html, _from, state) do
      {:reply, "rendered HTML", state}
    end

    def handle_call(:redirect, _from, state) do
      reason = {:shutdown, {:redirect, %{to: "/live/index"}}}
      {:stop, reason, state}
    end
  end

  property "with_timeout performs action or redirects" do
    check all(
            time_before_redirect <- frequency([{2, constant(0)}, {8, positive_integer()}]),
            time_before_action_finishes <- frequency([{2, constant(0)}, {8, positive_integer()}]),
            time_mounting_new_live_view <- frequency([{2, constant(0)}, {8, positive_integer()}]),
            timeout <- integer(100..500),
            id <- repeatedly(&make_ref/0),
            watcher_id <- repeatedly(&make_ref/0),
            max_run_time: to_timeout(second: 5)
          ) do
      {:ok, view_pid} = start_supervised(DummyLiveView, id: id)
      view = %{pid: view_pid}
      conn = Phoenix.ConnTest.build_conn()

      # LiveView can redirect at any point
      spawn(fn ->
        Process.sleep(time_before_redirect)
        DummyLiveView.redirect(view_pid)
      end)

      # start watcher _after_ LiveView is running (like in tests)
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}}, id: watcher_id)
      session = %Live{conn: conn, view: view, watcher: watcher}

      action = fn
        %{view: %{pid: ^view_pid}} ->
          Process.sleep(time_before_action_finishes)
          :action_performed

        _redirected_view ->
          Process.sleep(time_mounting_new_live_view)
          :redirected
      end

      fetch_redirect_info = fn _session ->
        # Just needs to be real path in case we get here
        {"/live/index", %{}}
      end

      # call with_timeout which we would do in an assertion
      result = LiveViewTimeout.with_timeout(session, timeout, action, fetch_redirect_info)

      assert result in [:redirected, :action_performed]
    end
  end

  describe "with_timeout/3" do
    setup do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      conn = Phoenix.ConnTest.build_conn()
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})
      session = %Live{conn: conn, view: view, watcher: watcher}

      {:ok, %{session: session}}
    end

    test "performs action if timeout is 0", %{session: session} do
      action = fn _session -> {:ok, :action_performed} end

      assert {:ok, :action_performed} = LiveViewTimeout.with_timeout(session, 0, action)
    end

    test "performs action at the end of timeout", %{session: session} do
      action = fn session -> DummyLiveView.render_html(session.view.pid) end

      assert "rendered HTML" = LiveViewTimeout.with_timeout(session, 100, action)
    end

    test "retries action at an interval when it fails", %{session: session} do
      action = fn session ->
        # Not deterministic, but close enough
        case Enum.random([:fail, :fail, :pass]) do
          :fail ->
            raise ExUnit.AssertionError, message: "Example failure"

          :pass ->
            DummyLiveView.render_html(session.view.pid)
        end
      end

      assert "rendered HTML" = LiveViewTimeout.with_timeout(session, 1000, action)
    end

    test "redirects when LiveView notifies of redirection", %{session: session} do
      %{view: %{pid: view_pid}} = session

      action = fn
        %{view: %{pid: ^view_pid}} ->
          DummyLiveView.redirect(view_pid)

        _redirected_view ->
          :redirected
      end

      assert :redirected = LiveViewTimeout.with_timeout(session, 1000, action)
    end

    test "tries to redirect if the LiveView dies before timeout", %{session: session} do
      %{view: %{pid: view_pid}} = session
      test_pid = self()

      action = fn
        %{view: %{pid: ^view_pid}} ->
          # Kill DummyLiveView and then attempt to send message
          # to emulate LiveView behavior
          Process.exit(view_pid, :kill)
          DummyLiveView.render_html(view_pid)

        _redirected_view ->
          :ok
      end

      fetch_redirect_info = fn session ->
        send(test_pid, {:redirect_attempted, from_view: session.view.pid})
        {"/live/index", %{}}
      end

      :ok = LiveViewTimeout.with_timeout(session, 1000, action, fetch_redirect_info)

      assert_receive {:redirect_attempted, from_view: ^view_pid}
    end
  end
end
