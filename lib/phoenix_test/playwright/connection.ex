defmodule PhoenixTest.Playwright.Connection do
  @moduledoc """
  Stateful, `GenServer` based connection to a Playwright node.js server.
  The connection is established via `Playwright.Port`.

  You won't usually have to use this module directly.
  `PhoenixTest.Case` uses this under the hood.
  """
  use GenServer

  alias PhoenixTest.Playwright.Port, as: PlaywrightPort

  @default_timeout_ms 1000
  @playwright_timeout_grace_period_ms 100

  defstruct [
    :port,
    :init,
    responses: %{},
    pending_init: [],
    pending_response: %{}
  ]

  @name __MODULE__

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: @name, timeout: timeout())
  end

  @doc """
  Lazy launch. Only start the playwright server if actually needed by a test.
  """
  def ensure_started(config) do
    case Process.whereis(@name) do
      nil -> start_link(config)
      pid -> {:ok, pid}
    end
  end

  @doc """
  Launch a browser and return its `guid`.
  """
  def launch_browser(type, opts) do
    type_id = GenServer.call(@name, {:browser_type_id, type})
    resp = sync_post(guid: type_id, method: "launch", params: Map.new(opts))
    resp.result.browser.guid
  end

  @doc """
  Fire and forget.
  """
  def post(msg) do
    GenServer.cast(@name, {:post, msg})
  end

  @doc """
  Post a message and await the response.
  We wait for an additional grace period after the timeout that we pass to playwright.

  We use double the default timeout if there is no message timeout, since some
  playwright operations use a backoff internally ([100, 250, 500, 1000]).
  """
  def sync_post(msg) do
    timeout = msg[:params][:timeout] || 2 * timeout()
    timeout_with_grace_period = timeout + @playwright_timeout_grace_period_ms
    GenServer.call(@name, {:sync_post, msg}, timeout_with_grace_period)
  end

  @doc """
  Get all past responses for a playwright `guid` (e.g. a `Frame`).
  The internal map used to track these responses is never cleaned, it will keep on growing.
  Since we're dealing with (short-lived) tests, that should be fine.
  """
  def responses(guid) do
    GenServer.call(@name, {:responses, guid})
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

  defp timeout do
    Application.get_env(:phoenix_test, :timeout_ms, @default_timeout_ms)
  end
end
