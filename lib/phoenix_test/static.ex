defmodule PhoenixTest.Static do
  @moduledoc false
  defstruct conn: nil, private: %{}

  def build(conn) do
    %__MODULE__{conn: conn}
  end

  def get_private(%__MODULE__{private: private}, key) do
    Map.get(private, key, :not_found)
  end

  def get_private(%__MODULE__{private: private}, key, default) do
    case Map.get(private, key, :not_found) do
      :not_found -> default
      found -> found
    end
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
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Utils

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
    |> html_response(conn.status)
  end

  def click_link(session, text) do
    click_link(session, "a", text)
  end

  def click_link(session, selector, text) do
    if data_attribute_form?(session, selector, text) do
      form =
        session
        |> render_html()
        |> Query.find!(selector, text)
        |> Html.DataAttributeForm.build()
        |> Html.DataAttributeForm.validate!(selector, text)

      session.conn
      |> dispatch(@endpoint, form.method, form.action, form.data)
      |> maybe_redirect(session)
    else
      path =
        session
        |> render_html()
        |> Query.find!(selector, text)
        |> Html.attribute("href")

      PhoenixTest.visit(session.conn, path)
    end
  end

  def click_button(session, text) do
    click_button(session, "button", text)
  end

  def click_button(session, selector, text) do
    cond do
      has_active_form?(session) ->
        session
        |> validate_submit_buttons!(selector, text)
        |> submit_active_form()

      data_attribute_form?(session, selector, text) ->
        form =
          session
          |> render_html()
          |> Query.find!(selector, text)
          |> Html.DataAttributeForm.build()
          |> Html.DataAttributeForm.validate!(selector, text)

        session.conn
        |> dispatch(@endpoint, form.method, form.action, form.data)
        |> maybe_redirect(session)

      true ->
        session
        |> validate_submit_buttons!(selector, text)
        |> single_button_form_submit(text)
    end
  end

  def fill_in(session, label, with: value) do
    html = render_html(session)

    input = Query.find_by_label!(html, label)
    input_id = Html.attribute(input, "id")

    form = Query.find_ancestor!(html, "form", input_id)
    id = Html.attribute(form, "id")

    new_form_data = Utils.name_to_map(Html.attribute(input, "name"), value)

    active_form = add_to_active_form_data(session, new_form_data)

    session
    |> PhoenixTest.Static.put_private(:active_form, active_form)
    |> fill_form("form##{id}", active_form.form_data)
  end

  defp add_to_active_form_data(session, new_form_data) do
    session
    |> PhoenixTest.Static.get_private(:active_form, %{form_data: %{}})
    |> Map.update(:form_data, %{}, fn form_data ->
      DeepMerge.deep_merge(form_data, new_form_data)
    end)
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

  defp data_attribute_form?(session, selector, text) do
    session
    |> render_html()
    |> Query.find(selector, text)
    |> case do
      {:found, element} ->
        method = Html.attribute(element, "data-method")
        method != "" && method != nil

      _ ->
        false
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
    method = form.parsed["operative_method"]

    session.conn
    |> dispatch(@endpoint, method, action, form.form_data)
    |> maybe_redirect(session)
  end

  defp single_button_form_submit(session, text) do
    form =
      session
      |> render_html()
      |> Query.find!("form", text)
      |> Html.Form.build()

    action = form["attributes"]["action"]
    method = form["operative_method"]

    session.conn
    |> dispatch(@endpoint, method, action)
    |> maybe_redirect(session)
  end

  def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])

    html =
      session.conn.resp_body
      |> Floki.parse_document!()
      |> Floki.traverse_and_update(&OpenBrowser.prefix_static_paths(&1, @endpoint))
      |> Floki.raw_html()

    File.write!(path, html)

    open_fun.(path)

    session
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
