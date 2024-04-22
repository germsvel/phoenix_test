defmodule PhoenixTest.Static do
  @moduledoc false

  alias PhoenixTest.ActiveForm

  defstruct conn: nil, active_form: ActiveForm.new(), within: :none, current_path: ""

  def build(conn) do
    current_path = conn.request_path <> "?" <> conn.query_string
    %__MODULE__{conn: conn, current_path: current_path}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  import Phoenix.ConnTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.Link
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Query

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  def render_page_title(session) do
    session
    |> render_html()
    |> Query.find("title")
    |> case do
      {:found, element} -> Html.text(element)
      _ -> nil
    end
  end

  def render_html(%{conn: conn, within: within}) do
    case within do
      :none ->
        html_response(conn, conn.status)

      selector ->
        conn
        |> html_response(conn.status)
        |> Query.find!(selector)
        |> Html.raw()
    end
  end

  def click_link(session, text) do
    click_link(session, "a", text)
  end

  def click_link(session, selector, text) do
    link =
      session
      |> render_html()
      |> Link.find!(selector, text)

    if Link.has_data_method?(link) do
      form =
        link.parsed
        |> Html.DataAttributeForm.build()
        |> Html.DataAttributeForm.validate!(selector, text)

      session.conn
      |> dispatch(@endpoint, form.method, form.action, form.data)
      |> maybe_redirect(session)
    else
      PhoenixTest.visit(session.conn, link.href)
    end
  end

  def click_button(session, text) do
    click_button(session, "button", text)
  end

  def click_button(session, selector, text) do
    active_form = session.active_form

    html = render_html(session)
    button = Button.find!(html, selector, text)

    if Button.has_data_method?(button) do
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

  def within(session, selector, fun) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, label, with: value) do
    session
    |> render_html()
    |> Field.find_input!(label)
    |> Map.put(:value, value)
    |> then(&fill_in_field_data(session, &1))
  end

  def select(session, option, from: label) do
    session
    |> render_html()
    |> Field.find_select_option!(label, option)
    |> then(&fill_in_field_data(session, &1))
  end

  def check(session, label) do
    session
    |> render_html()
    |> Field.find_checkbox!(label)
    |> then(&fill_in_field_data(session, &1))
  end

  def uncheck(session, label) do
    session
    |> render_html()
    |> Field.find_hidden_uncheckbox!(label)
    |> then(&fill_in_field_data(session, &1))
  end

  def choose(session, label) do
    session
    |> render_html()
    |> Field.find_input!(label)
    |> then(&fill_in_field_data(session, &1))
  end

  defp fill_in_field_data(session, field) do
    active_form = session.active_form
    existing_data = active_form.form_data
    new_form_data = Field.to_form_data(field)

    form = Field.parent_form!(field)

    form_data =
      if active_form.selector == form.selector do
        DeepMerge.deep_merge(existing_data, new_form_data)
      else
        new_form_data
      end

    fill_form(session, form.selector, form_data)
  end

  def submit(session) do
    active_form = session.active_form

    unless ActiveForm.active?(active_form), do: raise(no_active_form_error())

    selector = active_form.selector

    form =
      session
      |> render_html()
      |> Form.find!(selector)
      |> then(fn form ->
        Form.put_button_data(form, form.submit_button)
      end)

    submit_active_form(session, form)
  end

  defp no_active_form_error do
    %ArgumentError{
      message: "There's no active form. Fill in a form with `fill_in`, `select`, etc."
    }
  end

  def fill_form(session, selector, form_data) do
    form_data = Map.new(form_data, fn {k, v} -> {to_string(k), v} end)

    form =
      session
      |> render_html()
      |> Form.find!(selector)

    active_form =
      [id: form.id, selector: form.selector]
      |> ActiveForm.new()
      |> ActiveForm.prepend_form_data(form.form_data)
      |> ActiveForm.add_form_data(form_data)

    :ok =
      form.parsed
      |> Html.Form.build()
      |> Html.Form.validate_form_data!(active_form.form_data)

    Map.put(session, :active_form, active_form)
  end

  def submit_form(session, selector, form_data) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    session
    |> fill_form(selector, form_data)
    |> submit_active_form(form)
  end

  defp submit_active_form(session, form) do
    active_form = session.active_form
    form_data = DeepMerge.deep_merge(form.form_data, active_form.form_data)

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
