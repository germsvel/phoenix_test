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
  import Phoenix.LiveViewTest

  def visit(conn, path) do
    case live(conn, path) do
      {:ok, view, _html} ->
        PhoenixTest.Live.visit(view, conn)

      {:error, _} ->
        PhoenixTest.Static.visit(conn, path)
    end
  end
end
