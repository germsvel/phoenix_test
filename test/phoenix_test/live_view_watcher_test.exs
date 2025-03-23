defmodule PhoenixTest.LiveViewWatcherTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias PhoenixTest.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def redirect(pid) do
      GenServer.call(pid, :redirect)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call(:redirect, _from, state) do
      reason = {:shutdown, {:redirect, %{}}}
      {:stop, reason, state}
    end
  end

  property "watches for LiveViews to redirect or die" do
    check all(
            time_before_action <- frequency([{2, constant(0)}, {8, positive_integer()}]),
            id <- repeatedly(&make_ref/0),
            watcher_id <- repeatedly(&make_ref/0),
            action <- one_of([:kill, :redirect]),
            max_run_time: to_timeout(second: 5)
          ) do
      {:ok, view_pid} = start_supervised(DummyLiveView, id: id)
      view = %{pid: view_pid}
      {:ok, _watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}}, id: watcher_id)

      case action do
        :redirect ->
          spawn(fn ->
            Process.sleep(time_before_action)
            DummyLiveView.redirect(view_pid)
          end)

          assert_receive {:watcher, ^view_pid, {:live_view_redirected, _redirect_data}}

        :kill ->
          spawn(fn ->
            Process.sleep(time_before_action)
            Process.exit(view_pid, :kill)
          end)

          assert_receive {:watcher, ^view_pid, :live_view_died}
      end
    end
  end

  describe "start_link/1" do
    test "watches original view as soon as Watcher is started" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      %{views: views} = :sys.get_state(watcher)
      watched_views = Map.keys(views)

      assert view_pid in watched_views
    end
  end

  describe "watch_view/2" do
    test "sends :live_view_died message when LiveView dies" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view)

      Process.exit(view_pid, :kill)

      assert_receive {:watcher, ^view_pid, :live_view_died}
    end

    test "sends :live_view_redirected message when LiveView redirects" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view)

      spawn(fn ->
        DummyLiveView.redirect(view_pid)
      end)

      assert_receive {:watcher, ^view_pid, {:live_view_redirected, _redirect_data}}
    end

    test "does not overrides an (internal) live_view_ref info" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      %{views: views} = :sys.get_state(watcher)
      %{live_view_ref: live_view_ref} = views[view_pid]

      :ok = LiveViewWatcher.watch_view(watcher, view)

      %{views: views} = :sys.get_state(watcher)
      assert %{live_view_ref: ^live_view_ref} = views[view_pid]
    end

    test "can watch multiple LiveViews" do
      {:ok, view_pid1} = start_supervised(DummyLiveView, id: 1)
      {:ok, view_pid2} = start_supervised(DummyLiveView, id: 2)
      view1 = %{pid: view_pid1}
      view2 = %{pid: view_pid2}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view1}})

      :ok = LiveViewWatcher.watch_view(watcher, view1)
      :ok = LiveViewWatcher.watch_view(watcher, view2)

      %{views: views} = :sys.get_state(watcher)
      watched_views = Map.keys(views)

      assert view_pid1 in watched_views
      assert view_pid2 in watched_views
    end
  end
end
