defmodule PhoenixTest.Playwright.Port do
  @moduledoc """
  Start a Playwright node.js server and communicate with it via a `Port`.
  """

  alias PhoenixTest.Playwright.Message

  defstruct [
    :port,
    :remaining,
    :buffer
  ]

  def open(config \\ []) do
    config = :phoenix_test |> Application.fetch_env!(:playwright) |> Keyword.merge(config)
    cli = Keyword.fetch!(config, :cli)

    unless File.exists?(cli) do
      msg = """
      Could not find playwright CLI at #{cli}.

      To resolve this please
      1. Install playwright, e.g. `npm i playwright`
      2. Configure the path correctly, e.g. in `config/text.exs`: `config :phoenix_test, playwright: [cli: "assets/node_modules/playwright/cli.js"]`
      """

      raise ArgumentError, msg
    end

    cmd = "run-driver"
    port = Port.open({:spawn, "#{cli} #{cmd}"}, [:binary])

    %__MODULE__{port: port, remaining: 0, buffer: ""}
  end

  def post(state, msg) do
    frame = serialize(msg)
    length = byte_size(frame)
    padding = <<length::utf32-little>>
    Port.command(state.port, padding <> frame)
  end

  def parse(%{port: port} = state, {port, {:data, data}}) do
    parsed = Message.parse(data, state.remaining, state.buffer, [])
    %{frames: frames, buffer: buffer, remaining: remaining} = parsed
    state = %{state | buffer: buffer, remaining: remaining}
    msgs = Enum.map(frames, &deserialize/1)

    {state, msgs}
  end

  defp deserialize(json) do
    case Jason.decode(json) do
      {:ok, data} -> atom_keys(data)
      error -> decode_error(json, error)
    end
  end

  defp decode_error(json, error) do
    msg = "error: #{inspect(error)}; #{inspect(json: Enum.join(for <<c::utf8 <- json>>, do: <<c::utf8>>))}"
    raise ArgumentError, message: msg
  end

  defp serialize(message) do
    Jason.encode!(message)
  end

  defp atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_map(v) -> {String.to_atom(k), atom_keys(v)}
      {k, list} when is_list(list) -> {String.to_atom(k), Enum.map(list, fn v -> atom_keys(v) end)}
      {k, v} -> {String.to_atom(k), v}
    end)
  end

  defp atom_keys(other), do: other
end
