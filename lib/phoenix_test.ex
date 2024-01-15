defmodule PhoenixTest do
  @moduledoc """
  Documentation for `PhoenixTest`.
  """

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
