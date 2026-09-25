defmodule PhoenixTest.Verification.Recorder do
  @moduledoc false
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record(run_id, observation), do: GenServer.cast(__MODULE__, {:record, run_id, observation})

  def result(run_id), do: run_id |> results(1) |> hd()

  def results(run_id, count) when is_integer(count) and count > 0 do
    GenServer.call(__MODULE__, {:results, run_id, count}, 10_000)
  end

  @impl true
  def init(_), do: {:ok, %{observations: %{}, waiters: %{}}}

  @impl true
  def handle_cast({:record, run_id, observation}, state) do
    observations = Map.update(state.observations, run_id, [observation], &(&1 ++ [observation]))
    {:noreply, reply_waiters(%{state | observations: observations}, run_id)}
  end

  @impl true
  def handle_call({:results, run_id, count}, from, state) do
    waiters = Map.update(state.waiters, run_id, [{from, count}], &(&1 ++ [{from, count}]))
    {:noreply, reply_waiters(%{state | waiters: waiters}, run_id)}
  end

  defp reply_waiters(state, run_id) do
    case Map.get(state.waiters, run_id, []) do
      [{from, count} | rest] ->
        observations = Map.get(state.observations, run_id, [])
        {batch, remaining} = Enum.split(observations, count)

        if length(batch) == count do
          GenServer.reply(from, batch)

          state = %{
            state
            | observations: put_or_delete(state.observations, run_id, remaining),
              waiters: put_or_delete(state.waiters, run_id, rest)
          }

          reply_waiters(state, run_id)
        else
          state
        end

      [] ->
        state
    end
  end

  defp put_or_delete(map, key, []), do: Map.delete(map, key)
  defp put_or_delete(map, key, values), do: Map.put(map, key, values)
end
