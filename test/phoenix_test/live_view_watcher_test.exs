defmodule PhoenixTest.LiveViewWatcherTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer

    def start_link(opts \\ %{}) do
      GenServer.start_link(__MODULE__, opts)
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

  defmodule DummyLiveViewTestProxy do
    @moduledoc false
    use GenServer

    def start_link(opts \\ %{}) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:async_pids, {"empty_pids", nil, nil}}, _from, state) do
      {:reply, {:ok, []}, state}
    end

    def handle_call({:async_pids, {"async_pids", nil, nil}}, _from, state) do
      task =
        Task.async(fn ->
          Process.sleep(10)
          :ok
        end)

      {:reply, {:ok, [task.pid]}, state}
    end
  end

  test "watches original view as soon as Watcher is started" do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
    view = %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
    {:ok, _watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

    Process.exit(view_pid, :kill)

    assert_receive {:watcher, ^view_pid, :live_view_died}
  end

  describe "watch_view/2" do
    test "sends :live_view_died message when LiveView dies" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view = %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      Process.exit(view_pid, :kill)

      assert_receive {:watcher, ^view_pid, :live_view_died}
    end

    test "sends :live_view_redirected message when LiveView redirects" do
      {:ok, view_pid} = start_supervised({DummyLiveView, %{redirect_in: 10}})
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view = %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      assert_receive {:watcher, ^view_pid, {:live_view_redirected, _redirect_data}}
    end

    test "sends :timeout message when LiveView timeout expires" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view = %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 0)

      assert_receive {:watcher, ^view_pid, :timeout}
    end

    test "sends :async_process_completed message when async process completes" do
      {:ok, view_pid} = start_supervised(DummyLiveView)
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view = %{pid: view_pid, proxy: fake_proxy(proxy_pid, "async_pids")}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 100)

      assert_receive {:watcher, ^view_pid, :async_process_completed}
    end

    test "can override watch settings (e.g. timeout) for original LiveView" do
      {:ok, view_pid} = start_supervised(DummyLiveView, id: 1)
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view = %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

      :ok = LiveViewWatcher.watch_view(watcher, view, 0)

      assert_receive {:watcher, ^view_pid, :timeout}
    end

    test "can watch multiple LiveViews" do
      {:ok, view_pid1} = start_supervised(DummyLiveView, id: 1)
      {:ok, view_pid2} = start_supervised({DummyLiveView, %{redirect_in: 10}}, id: 2)
      {:ok, proxy_pid} = start_supervised(DummyLiveViewTestProxy)
      view1 = %{pid: view_pid1, proxy: fake_proxy(proxy_pid)}
      view2 = %{pid: view_pid2, proxy: fake_proxy(proxy_pid)}
      {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view1}})

      :ok = LiveViewWatcher.watch_view(watcher, view1, 0)
      :ok = LiveViewWatcher.watch_view(watcher, view2, 100)

      assert_receive {:watcher, ^view_pid1, :timeout}
      assert_receive {:watcher, ^view_pid2, {:live_view_redirected, _}}
    end
  end

  def fake_view(view_pid, proxy_pid) do
    %{pid: view_pid, proxy: fake_proxy(proxy_pid)}
  end

  defp fake_proxy(proxy_pid, proxy_topic \\ "empty_pids") do
    proxy_ref = make_ref()
    {proxy_ref, proxy_topic, proxy_pid}
  end
end
