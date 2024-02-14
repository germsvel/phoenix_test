defmodule PhoenixTest.Static do
  @moduledoc false
  defstruct conn: nil, private: %{}

  def build(conn) do
    %__MODULE__{conn: conn}
  end

  def get_private(%__MODULE__{private: private}, key) do
    Map.get(private, key, :not_found)
  end

  def pop_private(%__MODULE__{private: private} = session, key) do
    {popped, rest_private} = Map.pop(private, key, %{})
    {popped, %{session | private: rest_private}}
  end

  def put_private(%__MODULE__{private: private} = session, key, value) do
    updated_private = Map.put(private, key, value)
    %{session | private: updated_private}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def render_page_title(session) do
    session
    |> render_html()
    |> Query.find("title")
    |> case do
      {:found, element} -> Html.text(element)
      _ -> nil
    end
  end

  def render_html(%{conn: conn}) do
    conn
    |> html_response(200)
  end

  def click_link(session, text) do
    click_link(session, "a", text)
  end

  def click_link(session, selector, text) do
    path =
      session
      |> render_html()
      |> Query.find!(selector, text)
      |> Html.attribute("href")

    PhoenixTest.visit(session.conn, path)
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
      session
      |> validate_submit_buttons!(selector, text)
      |> single_button_form_submit(text)
    end
  end

  defp has_active_form?(session) do
    case PhoenixTest.Static.get_private(session, :active_form) do
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
    {form, session} = PhoenixTest.Static.pop_private(session, :active_form)
    action = form.parsed["attributes"]["action"]
    method = form.parsed["attributes"]["method"] || "get"

    session.conn
    |> dispatch(@endpoint, method, action, form.form_data)
    |> maybe_redirect(session)
  end

  defp single_button_form_submit(session, text) do
    form =
      session
      |> render_html()
      |> Query.find!("form", text)

    action = Html.attribute(form, "action")
    method = Html.attribute(form, "method") || "get"

    session.conn
    |> dispatch(@endpoint, method, action)
    |> maybe_redirect(session)
  end

  def fill_form(session, selector, form_data) do
    form =
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.Form.build()

    :ok = Html.Form.validate_form_data!(form, form_data)

    active_form = %{selector: selector, form_data: form_data, parsed: form}

    session
    |> PhoenixTest.Static.put_private(:active_form, active_form)
  end

  def submit_form(session, selector, form_data) do
    session
    |> fill_form(selector, form_data)
    |> submit_active_form()
  end

  defp maybe_redirect(conn, session) do
    case conn do
      %{status: 302} ->
        path = redirected_to(conn)
        PhoenixTest.visit(conn, path)

      %{status: _} ->
        %{session | conn: conn}
    end
  end
end
