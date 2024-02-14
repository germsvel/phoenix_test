defmodule PhoenixTest.Live do
  @moduledoc false
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  defstruct view: nil, conn: nil, private: %{}

  def build(conn) do
    {:ok, view, _html} = live(conn)
    %__MODULE__{view: view, conn: conn}
  end

  def get_private(%__MODULE__{private: private}, key) do
    Map.get(private, key, :not_found)
  end

  def pop_private(%__MODULE__{private: private} = session, key) do
    {popped, rest_private} = Map.pop(private, key, %{})
    {popped, %{session | private: rest_private}}
  end

  def put_private(%{private: private} = session, key, value) do
    new_private = Map.put(private, key, value)

    %{session | private: new_private}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def render_html(%{view: view}) do
    render(view)
  end

  def click_link(session, text) do
    click_link(session, "a", text)
  end

  def click_link(session, selector, text) do
    session.view
    |> element(selector, text)
    |> render_click()
    |> maybe_redirect(session)
  end

  def click_button(session, text) do
    click_button(session, "button", text)
  end

  def click_button(session, selector, text) do
    if has_active_form?(session) do
      session
      |> validate_submit_buttons!(selector, text)
      |> submit_active_form()
    else
      regular_click(session, selector, text)
    end
  end

  defp has_active_form?(session) do
    case PhoenixTest.Live.get_private(session, :active_form) do
      :not_found -> false
      _ -> true
    end
  end

  defp validate_submit_buttons!(session, selector, text) do
    submit_buttons = ["input[type=submit][value=#{text}]", {selector, text}]

    session
    |> render_html()
    |> Query.find_one_of!(submit_buttons)

    session
  end

  defp submit_active_form(session) do
    {form, session} = PhoenixTest.Live.pop_private(session, :active_form)

    cond do
      phx_submit_form?(session, form.selector) ->
        session.view
        |> form(form.selector, form.form_data)
        |> render_submit()
        |> maybe_redirect(session)

      action_form?(session, form.selector) ->
        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.submit_form(form.selector, form.form_data)

      true ->
        raise ArgumentError,
              "Expected form with selector #{inspect(form.selector)} to have a `phx-submit` or `action` defined."
    end
  end

  defp regular_click(session, selector, text) do
    session.view
    |> element(selector, text)
    |> render_click()
    |> maybe_redirect(session)
  end

  def fill_form(session, selector, form_data) do
    if phx_change_form?(session, selector) do
      session.view
      |> form(selector, form_data)
      |> render_change()
    else
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.Form.build()
      |> then(fn form ->
        :ok = Html.Form.validate_form_fields!(form["fields"], form_data)
      end)
    end

    session
    |> PhoenixTest.Live.put_private(:active_form, %{selector: selector, form_data: form_data})
  end

  defp action_form?(session, selector) do
    action =
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.attribute("action")

    action != nil && action != ""
  end

  defp phx_submit_form?(session, selector) do
    phx_submit =
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.attribute("phx-submit")

    phx_submit != nil && phx_submit != ""
  end

  defp phx_change_form?(session, selector) do
    phx_change =
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.attribute("phx-change")

    phx_change != nil && phx_change != ""
  end

  def submit_form(session, selector, form_data) do
    session.view
    |> form(selector, form_data)
    |> render_submit()
    |> maybe_redirect(session)
  end

  defp maybe_redirect({:error, {:redirect, %{to: path}}}, session) do
    PhoenixTest.visit(session.conn, path)
  end

  defp maybe_redirect({:error, {:live_redirect, _}} = result, session) do
    {:ok, view, _} = follow_redirect(result, session.conn)
    %{session | view: view}
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    session
  end
end
