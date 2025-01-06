defmodule PhoenixTest.LiveViewWatcher do
  @moduledoc false
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def watch_view(pid, timeout) do
    GenServer.cast(pid, {:watch_view, timeout})
  end

  def init(%{view: view, caller: caller}) do
    # Monitor the LiveView for exits and redirects
    live_view_ref = Process.monitor(view.pid)

    {:ok, %{caller: caller, view: view, live_view_ref: live_view_ref}}
  end

  def handle_cast({:watch_view, timeout}, state) do
    # Set timeout
    timeout_ref = make_ref()
    Process.send_after(self(), {timeout_ref, :timeout}, timeout)

    # Monitor all async processes
    case fetch_async_pids(state.view) do
      {:ok, pids} ->
        async_refs = Enum.map(pids, &Process.monitor(&1))

        state =
          state
          |> Map.put(:timeout_ref, timeout_ref)
          |> Map.put(:async_refs, async_refs)

        {:noreply, state}

      {:error, redirect_tuple} ->
        send(state.caller, {:watcher, :live_view_redirected, redirect_tuple})

        {:stop, :normal, state}
    end
  end

  def handle_info({timeout_ref, :timeout}, %{timeout_ref: timeout_ref} = state) do
    send(state.caller, {:watcher, :timeout})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, redirect_tuple}}, %{live_view_ref: ref} = state) do
    send(state.caller, {:watcher, :live_view_redirected, redirect_tuple})

    if Map.has_key?(state, :timeout_ref) do
      Process.cancel_timer(state.timeout_ref)
    end

    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{live_view_ref: ref} = state) do
    send(state.caller, {:watcher, :live_view_died})
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{async_refs: async_refs} = state) do
    if ref in async_refs do
      send(state.caller, {:watcher, :async_process_completed})
    end

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.debug(fn -> "Unhandled LiveViewWatcher message received. Message: #{inspect(message)}" end)

    {:noreply, state}
  end

  defp fetch_async_pids(view) do
    # Code copied (and simplified) from LiveViewTest's `render_async`
    # https://github.com/phoenixframework/phoenix_live_view/blob/09f7a8468ffd063a96b19767265c405898c9932e/lib/phoenix_live_view/test/live_view_test.ex#L940
    tuple = {:async_pids, {proxy_topic(view), nil, nil}}
    GenServer.call(proxy_pid(view), tuple, :infinity)
  catch
    :exit, {{:shutdown, {kind, opts}}, _} when kind in [:redirect, :live_redirect] ->
      {:error, {kind, opts}}

    :exit, _ ->
      {:ok, []}
  end

  defp proxy_pid(%{proxy: {_ref, _topic, pid}}), do: pid

  defp proxy_topic(%{proxy: {_ref, topic, _pid}}), do: topic
end
