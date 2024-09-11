defmodule PhoenixTest.LiveViewWatcher do
  @moduledoc false
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def watch_view(pid, timeout) do
    GenServer.cast(pid, {:watch_view, timeout})
  end

  def init(%{view: view, caller: from}) do
    Process.flag(:trap_exit, true)
    {:ok, %{caller: from, view: view}}
  end

  def handle_cast({:watch_view, timeout}, state) do
    # Set our timeout
    timeout_ref = make_ref()
    Process.send_after(self(), {timeout_ref, :timeout}, timeout)

    # Monitor the LiveView for exits and redirects
    live_view_ref = Process.monitor(state.view.pid)

    # Monitor all async processes
    pids = fetch_async_pids(state.view)
    async_refs = Enum.map(pids, &Process.monitor(&1))

    state =
      state
      |> Map.put(:timeout_ref, timeout_ref)
      |> Map.put(:live_view_ref, live_view_ref)
      |> Map.put(:async_refs, async_refs)

    {:noreply, state}
  end

  def handle_info({timeout_ref, :timeout}, %{timeout_ref: timeout_ref} = state) do
    send(state.caller, :timeout)

    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{live_view_ref: ref} = state) do
    {:shutdown, {live_or_redirect, %{kind: :push, to: path}}} = reason

    send(state.caller, {live_or_redirect, path})
    Process.cancel_timer(state.timeout_ref)
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{async_refs: async_refs} = state) do
    if ref in async_refs do
      # NOTE: delay sending in case of redirect as a result of async operation
      Process.send_after(state.caller, :async_process_completed, 50)
    end

    {:noreply, state}
  end

  def handle_info(message, state) do
    dbg(message)
    dbg(state)
    {:noreply, state}
  end

  defp fetch_async_pids(view) do
    # Code copied from LiveViewTest's `render_async`
    tuple = {:async_pids, {proxy_topic(view), nil, nil}}
    GenServer.call(proxy_pid(view), tuple, :infinity)
  catch
    :exit, {{:shutdown, {kind, opts}}, _} when kind in [:redirect, :live_redirect] ->
      {:error, {kind, opts}}

    :exit, {{exception, stack}, _} ->
      exit({{exception, stack}, {__MODULE__, :call, [view]}})
  else
    :ok -> :ok
    {:ok, result} -> result
    {:raise, exception} -> raise exception
  end

  defp proxy_pid(%{proxy: {_ref, _topic, pid}}), do: pid

  defp proxy_topic(%{proxy: {_ref, topic, _pid}}), do: topic
end
