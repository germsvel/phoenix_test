defmodule PhoenixTest.Static do
  @moduledoc false

  import Phoenix.ConnTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.DataAttributeForm
  alias PhoenixTest.Field
  alias PhoenixTest.FileUpload
  alias PhoenixTest.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.Html
  alias PhoenixTest.Link
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Query
  alias PhoenixTest.Select

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct conn: nil, active_form: ActiveForm.new(), within: :none, current_path: ""

  def build(conn) do
    current_path = append_query_string(conn.request_path, conn.query_string)
    %__MODULE__{conn: conn, current_path: current_path}
  end

  def current_path(session), do: session.current_path

  defp append_query_string(path, ""), do: path
  defp append_query_string(path, query), do: path <> "?" <> query

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

  def click_link(session, selector, text) do
    link =
      session
      |> render_html()
      |> Link.find!(selector, text)

    if Link.has_data_method?(link) do
      form =
        link.parsed
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!(selector, text)

      session.conn
      |> dispatch(@endpoint, form.method, form.action, form.data)
      |> maybe_redirect(session)
    else
      PhoenixTest.visit(session.conn, link.href)
    end
  end

  def click_button(session, selector, text) do
    active_form = session.active_form

    html = render_html(session)
    button = Button.find!(html, selector, text)

    if Button.has_data_method?(button) do
      form =
        button.parsed
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!(selector, text)

      session.conn
      |> dispatch(@endpoint, form.method, form.action, form.data)
      |> maybe_redirect(session)
    else
      form =
        button
        |> Button.parent_form!()
        |> Form.put_button_data(button)

      if active_form.selector == form.selector do
        submit_active_form(session, form)
      else
        submit(session, form)
      end
    end
  end

  def within(session, selector, fun) when is_function(fun, 1) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, input_selector, label, with: value) do
    session
    |> render_html()
    |> Field.find_input!(input_selector, label)
    |> Map.put(:value, to_string(value))
    |> then(&fill_in_field_data(session, &1))
  end

  def select(session, option, from: label) do
    session
    |> render_html()
    |> Select.find_select_option!(label, option)
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

  def choose(session, input_selector, label) do
    session
    |> render_html()
    |> Field.find_input!(input_selector, label)
    |> then(&fill_in_field_data(session, &1))
  end

  defp fill_in_field_data(session, field) do
    active_form = session.active_form
    existing_data = active_form.form_data
    new_form_data = FormData.to_form_data(field)

    form = Field.parent_form!(field)

    form_data =
      if active_form.selector == form.selector do
        existing_data ++ new_form_data
      else
        new_form_data
      end

    fill_form(session, form.selector, form_data)
  end

  def upload(session, label, path) do
    mime_type = FileUpload.mime_type(path)
    upload = %Plug.Upload{content_type: mime_type, filename: Path.basename(path), path: path}
    field = session |> render_html() |> Field.find_input!(label)
    form = Field.parent_form!(field)

    Map.update!(session, :active_form, fn active_form ->
      if active_form.selector == form.selector do
        ActiveForm.add_upload(active_form, {field.name, upload})
      else
        form
        |> ActiveForm.new()
        |> ActiveForm.add_upload({field.name, upload})
      end
    end)
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
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    active_form =
      form
      |> ActiveForm.new()
      |> ActiveForm.add_form_data(form_data)

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

    session = Map.put(session, :active_form, ActiveForm.new())

    session.conn
    |> dispatch(@endpoint, form.method, form.action, build_data(form, active_form))
    |> maybe_redirect(session)
  end

  defp submit(session, form) do
    session.conn
    |> dispatch(@endpoint, form.method, form.action, build_data(form))
    |> maybe_redirect(session)
  end

  defp build_data(form, active_form \\ ActiveForm.new()) do
    (form.form_data ++ active_form.form_data)
    |> Form.build_data()
    |> Form.inject_uploads(active_form.uploads)
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

  def unwrap(%{conn: conn} = session, fun) when is_function(fun, 1) do
    conn
    |> fun.()
    |> maybe_redirect(session)
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

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  alias PhoenixTest.Assertions
  alias PhoenixTest.Static

  defdelegate render_page_title(session), to: Static
  defdelegate render_html(session), to: Static
  defdelegate click(session, locator), to: Static
  defdelegate click_link(session, selector, text), to: Static
  defdelegate click_button(session, selector, text), to: Static
  defdelegate within(session, selector, fun), to: Static
  defdelegate fill_in(session, input_selector, label, attrs), to: Static
  defdelegate select(session, option, attrs), to: Static
  defdelegate check(session, label), to: Static
  defdelegate uncheck(session, label), to: Static
  defdelegate choose(session, input_selector, label), to: Static
  defdelegate upload(session, label, path), to: Static
  defdelegate submit(session), to: Static
  defdelegate open_browser(session), to: Static
  defdelegate open_browser(session, open_fun), to: Static
  defdelegate unwrap(session, fun), to: Static
  defdelegate current_path(session), to: Static

  defdelegate assert_has(session, selector), to: Assertions
  defdelegate assert_has(session, selector, opts), to: Assertions
  defdelegate refute_has(session, selector), to: Assertions
  defdelegate refute_has(session, selector, opts), to: Assertions
  defdelegate assert_path(session, path), to: Assertions
  defdelegate assert_path(session, path, opts), to: Assertions
  defdelegate refute_path(session, path), to: Assertions
  defdelegate refute_path(session, path, opts), to: Assertions
end
