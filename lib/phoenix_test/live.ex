defmodule PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  defstruct [:view, :conn]

  def build(conn) do
    {:ok, view, _html} = live(conn)
    %__MODULE__{view: view, conn: conn}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  def click_link(session, text) do
    result =
      session.view
      |> element("a", text)
      |> render_click()
      |> maybe_redirect(session)

    case result do
      {:ok, view, _} ->
        %{session | view: view}

      {:static_view, conn, path} ->
        PhoenixTest.visit(conn, path)
    end
  end

  def click_button(session, text) do
    result =
      session.view
      |> element("button", text)
      |> render_click()
      |> maybe_redirect(session)

    case result do
      {:ok, view, _} ->
        %{session | view: view}

      {:static_view, conn, path} ->
        PhoenixTest.visit(conn, path)
    end
  end

  @doc """
  Fills form data, validating that fields are present.

  It'll trigger phx-change events if they're present on the form.

  This can be followed by a `click_button` to submit the form.
  """
  def fill_form(session, selector, form_data) do
    # If form has phx-change trigger it.
    # Also, save form data in active form
    # submit_form on click_button if active form
    session.view
    |> form(selector, form_data)
    |> render_change()

    session
  end

  @doc """
  Submits form in the same way one would do by pressing <Enter>.
  Does not validate presence of submit button.
  """
  def submit_form(session, selector, form_data) do
    session.view
    |> form(selector, form_data)
    |> render_submit()

    session
  end

  def render_html(%{view: view}) do
    render(view)
  end

  defp maybe_redirect({:error, {:redirect, %{to: path}}}, session) do
    {:static_view, session.conn, path}
  end

  defp maybe_redirect({:error, {:live_redirect, _}} = result, session) do
    result
    |> follow_redirect(session.conn)
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    {:ok, session.view, html}
  end
end
