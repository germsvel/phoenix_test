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

      {:ok, opts}
    end

    def handle_info(:redirect, state) do
      reason = {:shutdown, {:redirect, %{}}}
      {:stop, reason, state}
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
      {:ok, view_pid} = start_supervised({DummyLiveView, %{redirect_in: 10}})
      view = %{pid: view_pid}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view)

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
      {:ok, view_pid1} = start_supervised({DummyLiveView, %{redirect_in: 10}}, id: 1)
      {:ok, view_pid2} = start_supervised({DummyLiveView, %{redirect_in: 10}}, id: 2)
      view1 = %{pid: view_pid1}
      view2 = %{pid: view_pid2}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view1}})

      :ok = LiveViewWatcher.watch_view(watcher, view1)
      :ok = LiveViewWatcher.watch_view(watcher, view2)

      assert_receive {:watcher, ^view_pid1, {:live_view_redirected, _redirect_data}}
      assert_receive {:watcher, ^view_pid2, {:live_view_redirected, _redirect_data}}
    end
  end
end
