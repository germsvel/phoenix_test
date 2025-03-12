defmodule PhoenixTest.LiveViewWatcher do
  @moduledoc false
  use GenServer, restart: :transient

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def watch_view(pid, live_view) do
    GenServer.cast(pid, {:watch_view, live_view})
  end

  def init(%{caller: caller, view: live_view}) do
    monitored_views = %{}
    {:ok, views} = add_to_monitored_views(monitored_views, live_view)

    {:ok, %{caller: caller, views: views}}
  end

  def handle_cast({:watch_view, live_view}, state) do
    {:ok, views} = add_to_monitored_views(state.views, live_view)

    {:noreply, %{state | views: views}}
  end

  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, {kind, _data} = redirect_tuple}}, state)
      when kind in [:redirect, :live_redirect] do
    case find_view_by_ref(state, ref) do
      {:ok, view} ->
        notify_caller(state, view.pid, {:live_view_redirected, redirect_tuple})
        state = remove_view(state, view.pid)

        {:noreply, state}

      :not_found ->
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case find_view_by_ref(state, ref) do
      {:ok, view} ->
        notify_caller(state, view.pid, :live_view_died)
        state = remove_view(state, view.pid)

        {:noreply, state}

      :not_found ->
        {:noreply, state}
    end
  end

  def handle_info(message, state) do
    Logger.debug(fn -> "Unhandled LiveViewWatcher message received. Message: #{inspect(message)}" end)

    {:noreply, state}
  end

  defp add_to_monitored_views(watched_views, live_view) do
    case watched_views[live_view.pid] do
      nil ->
        view = monitor_view(live_view)
        views = Map.put(watched_views, live_view.pid, view)
        {:ok, views}

      %{live_view_ref: _live_view_ref} = _already_watched ->
        {:ok, watched_views}
    end
  end

  defp monitor_view(live_view) do
    # Monitor the LiveView for exits and redirects
    live_view_ref = Process.monitor(live_view.pid)

    %{
      pid: live_view.pid,
      live_view_ref: live_view_ref
    }
  end

  defp notify_caller(state, view_pid, message) do
    send(state.caller, {:watcher, view_pid, message})
  end

  defp find_view_by_ref(state, ref) do
    Enum.find_value(state.views, :not_found, fn {_pid, view} ->
      if view.live_view_ref == ref, do: {:ok, view}
    end)
  end

  defp remove_view(state, view_pid) do
    case state.views[view_pid] do
      nil ->
        state

      _view ->
        %{state | views: Map.delete(state.views, view_pid)}
    end
  end
end
