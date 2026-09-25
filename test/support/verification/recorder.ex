defmodule PhoenixTest.Verification.Recorder do
  @moduledoc false
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record(run_id, observation), do: GenServer.cast(__MODULE__, {:record, run_id, observation})

  def result(run_id), do: GenServer.call(__MODULE__, {:result, run_id}, 10_000)

  @impl true
  def init(_), do: {:ok, %{observations: %{}, waiters: %{}}}

  @impl true
  def handle_cast({:record, run_id, observation}, state) do
    {waiters, remaining} = Map.pop(state.waiters, run_id, [])
    Enum.each(waiters, &GenServer.reply(&1, observation))

    observations =
      if waiters == [] do
        Map.put(state.observations, run_id, observation)
      else
        state.observations
      end

    {:noreply, %{state | observations: observations, waiters: remaining}}
  end

  @impl true
  def handle_call({:result, run_id}, from, state) do
    case Map.pop(state.observations, run_id) do
      {nil, _observations} ->
        {:noreply, %{state | waiters: Map.update(state.waiters, run_id, [from], &[from | &1])}}

      {observation, observations} ->
        {:reply, observation, %{state | observations: observations}}
    end
  end
end
