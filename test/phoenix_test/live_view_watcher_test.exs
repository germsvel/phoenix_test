defmodule PhoenixTest.LiveViewWatcherTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(opts) do
      {:ok, opts}
    end
  end

  defmodule DummyLiveViewTestProxy do
    @moduledoc false
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:async_pids, {"topic", nil, nil}}, _from, state) do
      {:reply, {:ok, []}, state}
    end
  end

  test "monitors a LiveView and notifies caller of it's death" do
    {:ok, view_pid} = start_supervised({DummyLiveView, []})
    {:ok, proxy_pid} = start_supervised({DummyLiveViewTestProxy, []})
    view = fake_view(view_pid, proxy_pid)
    {:ok, _watcher} = start_supervised({LiveViewWatcher, %{view: view, caller: self()}})

    Process.exit(view_pid, :kill)

    assert_receive {:watcher, :live_view_died}
  end

  test "sends :timeout message when LiveView timeout expires" do
    {:ok, view_pid} = start_supervised({DummyLiveView, []})
    {:ok, proxy_pid} = start_supervised({DummyLiveViewTestProxy, []})
    view = fake_view(view_pid, proxy_pid)
    {:ok, watcher} = start_supervised({LiveViewWatcher, %{view: view, caller: self()}})

    :ok = LiveViewWatcher.watch_view(watcher, 0)

    assert_receive {:watcher, :timeout}
  end

  def fake_view(view_pid, proxy_pid) do
    proxy_ref = make_ref()
    proxy_topic = "topic"
    %{pid: view_pid, proxy: {proxy_ref, proxy_topic, proxy_pid}}
  end
end
