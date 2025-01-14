defmodule PhoenixTest.LiveViewWatcherTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer

    def start_link(opts \\ %{}) do
      GenServer.start_link(__MODULE__, Map.new(opts))
    end

    def init(opts) do
      if opts[:redirect_in] do
        Process.send_after(self(), :redirect, opts[:redirect_in])
      end

      async_pids = Map.get(opts, :async_pids, [])

      {:ok, %{async_pids: async_pids}}
    end

    def handle_info(:redirect, state) do
      reason = {:shutdown, {:redirect, %{}}}
      {:stop, reason, state}
    end

    @prefix_from_live_view_channel :phoenix
    def handle_call({@prefix_from_live_view_channel, :async_pids}, _from, state) do
      {:reply, {:ok, state.async_pids}, state}
    end
  end

  describe "start_link/1" do
    test "watches original view as soon as Watcher is started" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, _watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      Process.exit(view_pid, :kill)

      assert_receive {:watcher, ^view_pid, :live_view_died}
    end
  end

  describe "watch_view/3" do
    test "sends :live_view_died message when LiveView dies" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      Process.exit(view_pid, :kill)

      assert_receive {:watcher, ^view_pid, :live_view_died}
    end

    test "sends :live_view_redirected message when LiveView redirects" do
      {:ok, view_pid} = start_supervised({DummyLiveView, %{redirect_in: 10}})
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      assert_receive {:watcher, ^view_pid, {:live_view_redirected, _redirect_data, timeout_left}}
      assert timeout_left > 0 and timeout_left < 100
    end

    test "sends :timeout message when LiveView timeout expires" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 0)

      assert_receive {:watcher, ^view_pid, :timeout}
    end

    test "sends :async_process_completed message when async process completes" do
      pid = spawn(fn -> :ok end)
      {:ok, view_pid} = start_supervised({DummyLiveView, %{async_pids: [pid]}})
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      assert_receive {:watcher, ^view_pid, :async_process_completed}
    end

    test "can override watch settings (e.g. timeout) for original LiveView" do
      # TODO: seems like we might be accidentally overriding the `live_view_ref`
      # and missing messages on patern matching in the watcher
      {:ok, view_pid} = start_supervised(DummyLiveView, id: 1)
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 0)

      assert_receive {:watcher, ^view_pid, :timeout}
    end

    test "can watch multiple LiveViews" do
      {:ok, view_pid1} = start_supervised(DummyLiveView, id: 1)
      {:ok, view_pid2} = start_supervised({DummyLiveView, %{redirect_in: 10}}, id: 2)
      view1 = %{pid: view_pid1}
      view2 = %{pid: view_pid2}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view1}})

      :ok = LiveViewWatcher.watch_view(watcher, view1, 0)
      :ok = LiveViewWatcher.watch_view(watcher, view2, 100)

      assert_receive {:watcher, ^view_pid1, :timeout}
      assert_receive {:watcher, ^view_pid2, {:live_view_redirected, _redirect_data, _timeout_left}}
    end
  end
end
