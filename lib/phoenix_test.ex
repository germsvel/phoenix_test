defmodule PhoenixTest do
  @moduledoc """
  Documentation for `PhoenixTest`.
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixTest
      import PhoenixTest.Driver
      import PhoenixTest.Assertions
    end
  end

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  def visit(conn, path) do
    case get(conn, path) do
      %{assigns: %{live_module: _}} = conn ->
        PhoenixTest.Live.build(conn)

      conn ->
        PhoenixTest.Static.build(conn)
    end
  end
end
