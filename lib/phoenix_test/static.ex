defmodule PhoenixTest.Static do
  @moduledoc false

  import Phoenix.ConnTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.ConnHandler
  alias PhoenixTest.DataAttributeForm
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Element.Link
  alias PhoenixTest.Element.Select
  alias PhoenixTest.FileUpload
  alias PhoenixTest.FormData
  alias PhoenixTest.FormPayload
  alias PhoenixTest.Html
  alias PhoenixTest.Locators
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Query

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct conn: nil, active_form: ActiveForm.new(), within: :none, current_path: ""

  def build(conn) do
    %__MODULE__{conn: conn, current_path: ConnHandler.build_current_path(conn)}
  end

  def current_path(session), do: session.current_path

  def render_page_title(session) do
    session
    |> render_html()
    |> Query.find("title")
    |> case do
      {:found, element} -> Html.inner_text(element)
      _ -> nil
    end
  end

  def render_html(%{conn: conn, within: within}) do
    html =
      conn
      |> html_response(conn.status)
      |> Html.parse_document()

    case within do
      :none -> html
      selector when is_binary(selector) -> Html.all(html, selector)
    end
  end

  def click_link(session, selector \\ "a", text) do
    link =
      session
      |> render_html()
      |> Link.find!(selector, text)

    if Link.has_data_method?(link) do
      form =
        link.parsed
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!(selector, text)

      perform_submit(session, form, form.data)
    else
      conn = session.conn

      conn
      |> ConnHandler.recycle_all_headers()
      |> PhoenixTest.visit(link.href)
    end
  end

  def click_button(session, text) do
    locator = Locators.button(text: text)
    html = render_html(session)

    button =
      html
      |> Query.find_by_role!(locator)
      |> Button.build(html)

    click_button(session, button.selector, button.text)
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

      perform_submit(session, form, form.data)
    else
      form =
        button
        |> Button.parent_form!()
        |> Form.put_button_data(button)

      if active_form.selector == form.selector do
        submit_active_form(session, form)
      else
        perform_submit(session, form, build_payload(form))
      end
    end
  end

  def fill_in(session, label, opts) do
    selectors = ["input:not([type='hidden'])", "textarea"]
    fill_in(session, selectors, label, opts)
  end

  def fill_in(session, input_selector, label, opts) do
    {value, opts} = Keyword.pop!(opts, :with)

    session
    |> render_html()
    |> Field.find_input!(input_selector, label, opts)
    |> Map.put(:value, to_string(value))
    |> then(&fill_in_field_data(session, &1))
  end

  def select(session, option, opts) do
    select(session, "select", option, opts)
  end

  def select(session, input_selector, option, opts) do
    {label, opts} = Keyword.pop!(opts, :from)

    session
    |> render_html()
    |> Select.find_select_option!(input_selector, label, option, opts)
    |> then(&fill_in_field_data(session, &1))
  end

  def check(session, label, opts) do
    check(session, "input[type='checkbox']", label, opts)
  end

  def check(session, input_selector, label, opts) do
    session
    |> render_html()
    |> Field.find_checkbox!(input_selector, label, opts)
    |> then(&fill_in_field_data(session, &1))
  end

  def uncheck(session, label, opts) do
    uncheck(session, "input[type='checkbox']", label, opts)
  end

  def uncheck(session, input_selector, label, opts) do
    session
    |> render_html()
    |> Field.find_hidden_uncheckbox!(input_selector, label, opts)
    |> then(&fill_in_field_data(session, &1))
  end

  def choose(session, label, opts) do
    choose(session, "input[type='radio']", label, opts)
  end

  def choose(session, input_selector, label, opts) do
    session
    |> render_html()
    |> Field.find_input!(input_selector, label, opts)
    |> then(&fill_in_field_data(session, &1))
  end

  def upload(session, label, path, opts) do
    upload(session, "input[type='file']", label, path, opts)
  end

  def upload(session, input_selector, label, path, opts) do
    mime_type = FileUpload.mime_type(path)
    upload = %Plug.Upload{content_type: mime_type, filename: Path.basename(path), path: path}
    field = session |> render_html() |> Field.find_input!(input_selector, label, opts)
    form = Field.parent_form!(field)
    upload_data = {field.name, upload}

    Map.update!(session, :active_form, fn active_form ->
      if active_form.selector == form.selector do
        ActiveForm.add_upload(active_form, upload_data)
      else
        [id: form.id, selector: form.selector]
        |> ActiveForm.new()
        |> ActiveForm.add_upload(upload_data)
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

  def submit_form(session, selector, form_data) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)
      |> then(fn form ->
        Form.put_button_data(form, form.submit_button)
      end)

    to_submit = FormPayload.new(FormData.merge(form.form_data, form_data))

    session
    |> Map.put(:active_form, ActiveForm.new())
    |> perform_submit(form, to_submit)
  end

  def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])

    html =
      session.conn.resp_body
      |> Html.parse_document()
      |> Html.postwalk(&OpenBrowser.prefix_static_paths(&1, @endpoint))
      |> Html.raw()

    File.write!(path, html)

    open_fun.(path)

    session
  end

  def unwrap(%{conn: conn} = session, fun) when is_function(fun, 1) do
    conn
    |> fun.()
    |> maybe_redirect(session)
  end

  defp fill_in_field_data(session, field) do
    Field.validate_name!(field)
    form = Field.parent_form!(field)

    Map.update!(session, :active_form, fn active_form ->
      if active_form.selector == form.selector do
        ActiveForm.add_form_data(active_form, field)
      else
        [id: form.id, selector: form.selector]
        |> ActiveForm.new()
        |> ActiveForm.add_form_data(field)
      end
    end)
  end

  defp submit_active_form(session, form) do
    active_form = session.active_form

    session
    |> Map.put(:active_form, ActiveForm.new())
    |> perform_submit(form, build_payload(form, active_form))
  end

  defp perform_submit(session, form, payload) do
    conn = session.conn

    conn
    |> ConnHandler.recycle_all_headers()
    |> dispatch(@endpoint, form.method, form.action, payload)
    |> maybe_redirect(session)
  end

  defp no_active_form_error do
    %ArgumentError{
      message: "There's no active form. Fill in a form with `fill_in`, `select`, etc."
    }
  end

  defp build_payload(form, active_form \\ ActiveForm.new()) do
    form.form_data
    |> FormData.merge(active_form.form_data)
    |> FormPayload.new()
    |> FormPayload.add_form_data(active_form.uploads)
  end

  defp maybe_redirect(conn, session) do
    case conn do
      %{status: 302} ->
        path = redirected_to(conn)

        conn
        |> ConnHandler.recycle_all_headers()
        |> PhoenixTest.visit(path)

      %{status: _} ->
        %{session | conn: conn, current_path: ConnHandler.build_current_path(conn)}
    end
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  alias PhoenixTest.Assertions
  alias PhoenixTest.ConnHandler
  alias PhoenixTest.SessionHelpers
  alias PhoenixTest.Static

  def visit(session, path) do
    ConnHandler.visit(session.conn, path)
  end

  defdelegate render_page_title(session), to: Static
  defdelegate render_html(session), to: Static
  defdelegate click_link(session, text), to: Static
  defdelegate click_link(session, selector, text), to: Static
  defdelegate click_button(session, text), to: Static
  defdelegate click_button(session, selector, text), to: Static
  defdelegate within(session, selector, fun), to: SessionHelpers
  defdelegate fill_in(session, label, opts), to: Static
  defdelegate fill_in(session, input_selector, label, opts), to: Static
  defdelegate select(session, option, opts), to: Static
  defdelegate select(session, input_selector, option, opts), to: Static
  defdelegate check(session, label, opts), to: Static
  defdelegate check(session, input_selector, label, opts), to: Static
  defdelegate uncheck(session, label, opts), to: Static
  defdelegate uncheck(session, input_selector, label, opts), to: Static
  defdelegate choose(session, label, opts), to: Static
  defdelegate choose(session, input_selector, label, opts), to: Static
  defdelegate upload(session, label, path, opts), to: Static
  defdelegate upload(session, input_selector, label, path, opts), to: Static
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
