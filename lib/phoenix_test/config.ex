defmodule PhoenixTest.Config do
  @moduledoc false

  @process_key :phoenix_test_endpoint

  def put_endpoint(endpoint) when is_atom(endpoint) do
    Process.put(@process_key, endpoint)
    :ok
  end

  def endpoint do
    Process.get(@process_key) || Application.get_env(:phoenix_test, :endpoint)
  end

  def endpoint! do
    endpoint() ||
      raise ArgumentError, """
      No endpoint configured for PhoenixTest.

      Set it per-test-process in your test setup (recommended for umbrella apps):

          setup do
            PhoenixTest.Config.put_endpoint(MyAppWeb.Endpoint)
            :ok
          end

      Or set it on the conn directly:

          {:ok, conn: Phoenix.ConnTest.build_conn() |> PhoenixTest.put_endpoint(MyAppWeb.Endpoint)}

      Or set it globally in config/test.exs:

          config :phoenix_test, :endpoint, MyAppWeb.Endpoint
      """
  end
end
