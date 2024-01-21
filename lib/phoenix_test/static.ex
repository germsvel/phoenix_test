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

  def click_link(session, text) do
    path =
      session
      |> render_html()
      |> Html.parse()
      |> Html.find("a", text)
      |> Html.attribute("href")

    PhoenixTest.visit(session.conn, path)
  end

  def click_button(session, text) do
    if has_active_form?(session) do
      session
      |> validate_submit_buttons(text)
      |> submit_active_form()
    else
      single_button_form_submit(session, text)
    end
  end

  defp has_active_form?(session) do
    case PhoenixTest.Static.get_private(session, :active_form) do
      :not_found -> false
      _ -> true
    end
  end

  defp validate_submit_buttons(session, text) do
    session
    |> render_html()
    |> Html.parse()
    |> Html.find_one_of(["input[type=submit][value=#{text}]", {"button", text}])

    session
  end

  defp submit_active_form(session) do
    {form, session} = PhoenixTest.Static.pop_private(session, :active_form)
    action = form["action"]
    method = form["method"] || "get"

    data = form["data"]

    conn = dispatch(session.conn, @endpoint, method, action, data)

    %{session | conn: conn}
  end

  defp single_button_form_submit(session, text) do
    form =
      session
      |> render_html()
      |> Html.parse()
      |> Html.find("form", text)

    action = Html.attribute(form, "action")
    method = Html.attribute(form, "method") || "get"

    conn = dispatch(session.conn, @endpoint, method, action)

    %{session | conn: conn}
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
      |> Html.parse()
      |> Html.find(selector)
      |> Html.Form.parse()
      |> Map.put("data", form_data)

    :ok = verify_expected_form_data(form, form_data)

    session
    |> PhoenixTest.Static.put_private(:active_form, form)
  end

  defp verify_expected_form_data(form, form_data) do
    action = form["action"]
    unless action, do: raise("expected form to have an action but found none")

    existing_inputs = form["inputs"]

    form_data
    |> Enum.each(fn
      {key, value} when is_binary(value) ->
        verify_input_presence(to_string(key), existing_inputs)

      {key, values} when is_map(values) ->
        Enum.map(values, fn {nested_key, _nested_value} ->
          combined_key = "#{to_string(key)}[#{to_string(nested_key)}]"
          verify_input_presence(combined_key, existing_inputs)
        end)
    end)
  end

  defp verify_input_presence(expected_input, existing_inputs) do
    key = expected_input

    if !Enum.any?(existing_inputs, fn input ->
         input["name"] == key
       end) do
      raise """
        Expected form to have #{inspect(key)} input, but found none.

        Found inputs: #{Enum.map_join(existing_inputs, ", ", & &1["name"])}
      """
    end
  end

  def render_html(%{conn: conn}) do
    conn
    |> html_response(200)
  end
end
