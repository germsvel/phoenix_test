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

  @doc """
  Submits parent form. Could be preceded by `fill_form` or used alone if form
  has a single button (e.g. "Delete").
  """
  defdelegate click_button(session, text), to: Driver

  @doc """
  Fills form data, validating that fields are present.

  It'll trigger phx-change events if they're present on the form.

  This can be followed by a `click_button` to submit the form.
  """
  defdelegate fill_form(session, selector, data), to: Driver

  @doc """
  Submits form in the same way one would do by pressing <Enter>.
  Does not validate presence of submit button.
  """
  defdelegate submit_form(session, selector, data), to: Driver
  defdelegate assert_has(session, selector, text), to: Assertions
  defdelegate refute_has(session, selector, text), to: Assertions
end
