defmodule PhoenixTest.Static do
  @moduledoc false

  alias PhoenixTest.ActiveForm

  defstruct conn: nil, active_form: ActiveForm.new()

  def build(conn) do
    %__MODULE__{conn: conn}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.OpenBrowser
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
    active_form = session.active_form

    html = render_html(session)
    button = Button.find!(html, selector, text)

    if data_attribute_form?(session, selector, text) do
      form =
        button.parsed
        |> Html.DataAttributeForm.build()
        |> Html.DataAttributeForm.validate!(selector, text)

      session.conn
      |> dispatch(@endpoint, form.method, form.action, form.data)
      |> maybe_redirect(session)
    else
      form =
        html
        |> Form.find_by_descendant!(button)
        |> Form.put_button_data(button)

      if active_form.selector == form.selector do
        submit_active_form(session, form)
      else
        submit(session, form)
      end
    end
  end

  def fill_in(session, label, with: value) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label, value)

    new_form_data = Field.to_form_data(field)

    active_form = session.active_form |> ActiveForm.add_form_data(new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form(form.selector, active_form.form_data)
  end

  def select(session, option, from: label) do
    field =
      session
      |> render_html()
      |> Field.find_select_option!(label, option)

    new_form_data = Field.to_form_data(field)

    active_form = session.active_form |> ActiveForm.add_form_data(new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form(form.selector, active_form.form_data)
  end

  def check(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_checkbox!(label)

    new_form_data = Field.to_form_data(field)

    active_form = session.active_form |> ActiveForm.add_form_data(new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form(form.selector, active_form.form_data)
  end

  def uncheck(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_hidden_uncheckbox!(label)

    new_form_data = Field.to_form_data(field)

    active_form = session.active_form |> ActiveForm.add_form_data(new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form(form.selector, active_form.form_data)
  end

  def choose(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label)

    new_form_data = Field.to_form_data(field)

    active_form = session.active_form |> ActiveForm.add_form_data(new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form(form.selector, active_form.form_data)
  end

  def fill_form(session, selector, form_data) do
    form_data = Map.new(form_data, fn {k, v} -> {to_string(k), v} end)

    form =
      session
      |> render_html()
      |> Form.find!(selector)

    form = update_in(form.form_data, fn data -> Map.merge(data, form_data) end)

    :ok =
      form.parsed
      |> Html.Form.build()
      |> Html.Form.validate_form_data!(form_data)

    session
    |> Map.put(:active_form, form)
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

  defp submit_active_form(session) do
    active_form = Map.get(session, :active_form)
    action = active_form.action
    method = active_form.method

    session = Map.put(session, :active_form, ActiveForm.new())

    session.conn
    |> dispatch(@endpoint, method, action, active_form.form_data)
    |> maybe_redirect(session)
  end

  defp submit_active_form(session, form) do
    active_form = Map.get(session, :active_form)
    form_data = Map.merge(form.form_data, active_form.form_data)

    session = Map.put(session, :active_form, ActiveForm.new())

    session.conn
    |> dispatch(@endpoint, form.method, form.action, form_data)
    |> maybe_redirect(session)
  end

  defp submit(session, form) do
    session.conn
    |> dispatch(@endpoint, form.method, form.action, form.form_data)
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
