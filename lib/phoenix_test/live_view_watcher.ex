defmodule PhoenixTest.LiveViewWatcher do
  @moduledoc false
  use GenServer, restart: :transient

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def watch_view(pid, live_view, timeout) do
    GenServer.cast(pid, {:watch_view, live_view, timeout})
  end

  def init(%{caller: caller, view: live_view}) do
    # Monitor the LiveView for exits and redirects
    live_view_ref = Process.monitor(live_view.pid)

    view = %{pid: live_view.pid, live_view_ref: live_view_ref}
    views = %{view.pid => view}

    {:ok, %{caller: caller, views: views}}
  end

  def handle_cast({:watch_view, live_view, timeout}, state) do
    case monitor_view(live_view, timeout, state.views) do
      {:ok, view} ->
        views = Map.put(state.views, view.pid, view)

        {:noreply, %{state | views: views}}

      {:error, redirect_tuple} ->
        notify_caller(state, live_view.pid, {:live_view_redirected, redirect_tuple, timeout})

        {:noreply, state}
    end
  end

  def handle_info({:timeout, view_pid}, state) do
    case state.views[view_pid] do
      %{timeout_ref: _timeout_ref} ->
        notify_caller(state, view_pid, :timeout)

        {:noreply, state}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, {kind, _data} = redirect_tuple}}, state)
      when kind in [:redirect, :live_redirect] do
    case find_view_by_ref(state, ref) do
      {:ok, view} ->
        timeout_left = (Map.has_key?(view, :timeout_ref) && Process.cancel_timer(view.timeout_ref)) || 0
        notify_caller(state, view.pid, {:live_view_redirected, redirect_tuple, timeout_left})
        state = remove_view(state, view.pid)

        {:noreply, state}

      :not_found ->
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    cond do
      match?({:ok, _view}, find_view_by_ref(state, ref)) ->
        {:ok, view} = find_view_by_ref(state, ref)
        notify_caller(state, view.pid, :live_view_died)
        state = remove_view(state, view.pid)

        if Map.has_key?(view, :timeout_ref) do
          Process.cancel_timer(view.timeout_ref)
        end

        {:noreply, state}

      match?({:ok, _view}, find_view_by_async_ref(state, ref)) ->
        {:ok, view} = find_view_by_async_ref(state, ref)
        notify_caller(state, view.pid, :async_process_completed)

        view = remove_async_ref(view, ref)
        views = Map.put(state.views, view.pid, view)

        {:noreply, %{state | views: views}}

      true ->
        {:noreply, state}
    end
  end

  def handle_info(message, state) do
    Logger.debug(fn -> "Unhandled LiveViewWatcher message received. Message: #{inspect(message)}" end)

    {:noreply, state}
  end

  defp monitor_view(live_view, timeout, watched_views) do
    # Monitor the LiveView for exits and redirects
    live_view_ref =
      case watched_views[live_view.pid] do
        nil -> Process.monitor(live_view.pid)
        %{live_view_ref: live_view_ref} -> live_view_ref
      end

    # Set timeout
    timeout_ref = Process.send_after(self(), {:timeout, live_view.pid}, timeout)

    # Monitor all async processes
    case fetch_async_pids(live_view) do
      {:ok, pids} ->
        async_refs = Enum.map(pids, &Process.monitor(&1))

        view_data =
          %{
            pid: live_view.pid,
            live_view_ref: live_view_ref,
            timeout_ref: timeout_ref,
            async_refs: async_refs
          }

        {:ok, view_data}

      {:error, _redirect_tuple} = error ->
        error
    end
  end

  defp notify_caller(state, view_pid, message) do
    send(state.caller, {:watcher, view_pid, message})
  end

  defp find_view_by_ref(state, ref) do
    Enum.find_value(state.views, :not_found, fn {_pid, view} ->
      if view.live_view_ref == ref, do: {:ok, view}
    end)
  end

  defp find_view_by_async_ref(state, ref) do
    Enum.find_value(state.views, :not_found, fn {_pid, view} ->
      if ref in view.async_refs, do: {:ok, view}
    end)
  end

  defp fetch_async_pids(view) do
    # Code copied (and simplified) from LiveViewTest's `render_async`:
    # https://github.com/phoenixframework/phoenix_live_view/blob/09f7a8468ffd063a96b19767265c405898c9932e/lib/phoenix_live_view/test/live_view_test.ex#L940
    #
    # which ends up calling `LiveView.Channel.async_pids`:
    # https://github.com/phoenixframework/phoenix_live_view/blob/09f7a8468ffd063a96b19767265c405898c9932e/lib/phoenix_live_view/channel.ex#L49
    #
    # We target the `Channel` call here so we can properly catch exits when the
    # LiveView dies.
    Phoenix.LiveView.Channel.async_pids(view.pid)
  catch
    :exit, {{:shutdown, {kind, opts}}, _} when kind in [:redirect, :live_redirect] ->
      {:error, {kind, opts}}

    :exit, _e ->
      {:ok, []}
  end

  defp remove_view(state, view_pid) do
    case state.views[view_pid] do
      nil ->
        state

      _view ->
        %{state | views: Map.delete(state.views, view_pid)}
    end
  end

  def remove_async_ref(view, ref) do
    Map.update!(view, :async_refs, &List.delete(&1, ref))
  end
end
