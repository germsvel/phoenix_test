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
      |> render_html()
      |> find_submit_buttons!(selector, text)

      session
      |> submit_active_form()
    else
      session
      |> render_html()
      |> find_submit_buttons!(selector, text)

      session
      |> single_button_form_submit(text)
    end
  end

  defp has_active_form?(session) do
    case PhoenixTest.Static.get_private(session, :active_form) do
      :not_found -> false
      _ -> true
    end
  end

  defp find_submit_buttons!(html, selector, text) do
    submit_buttons = ["input[type=submit][value=#{text}]", {selector, text}]

    Query.find_one_of!(html, submit_buttons)
  end

  defp submit_active_form(session) do
    {form, session} = PhoenixTest.Static.pop_private(session, :active_form)
    action = form["action"]
    method = form["method"] || "get"

    data = form["data"]

    session.conn
    |> dispatch(@endpoint, method, action, data)
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

  def submit_form(session, selector, form_data) do
    session
    |> fill_form(selector, form_data)
    |> submit_active_form()
  end

  def fill_form(session, selector, form_data) do
    form =
      session
      |> render_html()
      |> Query.find!(selector)
      |> Html.Form.parse()
      |> Map.put("data", form_data)

    :ok = verify_expected_form_data(form, form_data)

    session
    |> PhoenixTest.Static.put_private(:active_form, form)
  end

  def render_html(%{conn: conn}) do
    conn
    |> html_response(200)
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

  defp verify_expected_form_data(form, form_data) do
    action = form["action"]
    unless action, do: raise("Expected form to have an action but found none")

    validate_expected_fields(form["fields"], form_data)
  end

  defp validate_expected_fields(existing_fields, form_data) do
    form_data
    |> Enum.each(fn
      {key, values} when is_map(values) ->
        Enum.each(values, fn {nested_key, nested_value} ->
          combined_key = "#{to_string(key)}[#{to_string(nested_key)}]"
          validate_expected_fields(existing_fields, %{combined_key => nested_value})
        end)

      {key, _value} ->
        verify_field_presence(existing_fields, to_string(key))
    end)
  end

  defp verify_field_presence([], expected_field) do
    raise ArgumentError, """
    Expected form to have #{inspect(expected_field)} form field, but found no
    existing fields.
    """
  end

  defp verify_field_presence(existing_fields, expected_field) do
    if Enum.all?(existing_fields, fn field ->
         field["name"] != expected_field
       end) do
      raise ArgumentError, """
      Expected form to have #{inspect(expected_field)} form field, but found none.

      Found the following fields:

       - #{Enum.map_join(existing_fields, "\n - ", &format_field_error/1)}
      """
    end
  end

  defp format_field_error(field) do
    "#{field["type"]} with name=#{inspect(field["name"])}"
  end
end
