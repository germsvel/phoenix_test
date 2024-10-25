defmodule PhoenixTest.Playwright.Connection do
  @moduledoc false
  use GenServer

  alias PhoenixTest.Playwright.Port, as: PlaywrightPort

  defstruct [
    :port,
    :init,
    responses: %{},
    pending_init: [],
    pending_response: %{}
  ]

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__, timeout: 1000)
  end

  def ensure_started(name \\ __MODULE__, config) do
    case Process.whereis(name) do
      nil -> start_link(config)
      pid -> {:ok, pid}
    end
  end

  def launch_browser(name \\ __MODULE__, type, opts) do
    type_id = GenServer.call(name, {:browser_type_id, type})
    resp = sync_post(guid: type_id, method: "launch", params: Map.new(opts))
    resp.result.browser.guid
  end

  def post(name \\ __MODULE__, msg) do
    GenServer.cast(name, {:post, msg})
  end

  def sync_post(name \\ __MODULE__, msg) do
    GenServer.call(name, {:sync_post, msg})
  end

  def responses(name \\ __MODULE__, guid) do
    GenServer.call(name, {:responses, guid})
  end

  @impl GenServer
  def init(config) do
    port = PlaywrightPort.open(config)
    msg = %{guid: "", params: %{sdkLanguage: "javascript"}, method: "initialize"}
    PlaywrightPort.post(port, msg)

    {:ok, %__MODULE__{port: port}}
  end

  @impl GenServer
  def handle_cast({:post, msg}, state) do
    PlaywrightPort.post(state.port, msg)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:sync_post, msg}, from, state) do
    msg_id = fn -> System.unique_integer([:positive, :monotonic]) end
    msg = msg |> Map.new() |> Map.put_new_lazy(:id, msg_id)
    PlaywrightPort.post(state.port, msg)

    {:noreply, Map.update!(state, :pending_response, &Map.put(&1, msg.id, from))}
  end

  def handle_call({:responses, guid}, _from, state) do
    {:reply, Map.get(state.responses, guid, []), state}
  end

  def handle_call({:browser_type_id, type}, from, %{init: nil} = state) do
    fun = &GenServer.reply(from, browser_type_id(&1, type))
    {:noreply, Map.update!(state, :pending_init, &[fun | &1])}
  end

  def handle_call({:browser_type_id, type}, _from, state) do
    {:reply, browser_type_id(state.init, type), state}
  end

  @impl GenServer
  def handle_info({_, {:data, _}} = raw_msg, state) do
    {port, msgs} = PlaywrightPort.parse(state.port, raw_msg)
    state = %{state | port: port}
    state = Enum.reduce(msgs, state, &handle_recv/2)

    {:noreply, state}
  end

  defp handle_recv(%{params: %{type: "Playwright"}} = msg, state) do
    init = msg.params.initializer
    for fun <- state.pending_init, do: fun.(init)

    %{state | init: init, pending_init: :done}
  end

  defp handle_recv(msg, %{pending_response: pending} = state) when is_map_key(pending, msg.id) do
    {from, pending} = Map.pop(pending, msg.id)
    GenServer.reply(from, msg)

    %{state | pending_response: pending}
  end

  defp handle_recv(%{guid: guid} = msg, state) do
    update_in(state.responses[guid], &[msg | &1 || []])
  end

  defp handle_recv(_msg, state), do: state

  defp browser_type_id(init, type), do: Map.fetch!(init, type).guid
end
