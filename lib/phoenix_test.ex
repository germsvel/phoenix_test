defmodule PhoenixTest do
  @moduledoc """
  Documentation for `PhoenixTest`.
  """

  alias PhoenixTest.Driver
  alias PhoenixTest.Assertions

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

  defdelegate click_link(session, text), to: Driver
  defdelegate click_button(session, text), to: Driver
  defdelegate fill_form(session, selector, data), to: Driver
  defdelegate submit_form(session, selector, data), to: Driver
  defdelegate assert_has(session, selector, text), to: Assertions
  defdelegate refute_has(session, selector, text), to: Assertions
end
