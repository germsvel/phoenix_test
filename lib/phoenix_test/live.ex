defmodule PhoenixTest.Live do
  @moduledoc false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Assertions
  alias PhoenixTest.ConnHandler
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Element.Select
  alias PhoenixTest.FileUpload
  alias PhoenixTest.FormData
  alias PhoenixTest.FormPayload
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewTimeout
  alias PhoenixTest.Locators
  alias PhoenixTest.Query

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct view: nil, watcher: nil, conn: nil, active_form: ActiveForm.new(), within: :none, current_path: ""

  def build(conn) do
    {:ok, view, _html} = live(conn)
    current_path = ConnHandler.build_current_path(conn)
    {:ok, watcher} = start_watcher(view)
    %__MODULE__{view: view, watcher: watcher, conn: conn, current_path: current_path}
  end

  defp start_watcher(view) do
    ExUnit.Callbacks.start_supervised({PhoenixTest.LiveViewWatcher, %{caller: self(), view: view}},
      id: make_ref()
    )
  end

  def current_path(session), do: session.current_path

  def render_page_title(%{view: view}) do
    page_title(view)
  end

  def render_html(%{view: view, within: within}) do
    html =
      view
      |> render()
      |> Html.parse_fragment()

    case within do
      :none -> html
      selector when is_binary(selector) -> Html.all(html, selector)
    end
  end

  def click_link(session, selector \\ "a", text) do
    session.view
    |> element(selector, text)
    |> render_click()
    |> maybe_redirect(session)
  end

  def click_button(session, text) do
    locator = Locators.button(text: text)
    html = render_html(session)

    button =
      html
      |> Query.find_by_role!(locator)
      |> Button.build(html)

    handle_click_button(session, button)
  end

  def click_button(session, selector, text) do
    button =
      session
      |> render_html()
      |> Button.find!(selector, text)

    handle_click_button(session, button)
  end

  defp handle_click_button(session, button) do
    button = %{button | selector: PhoenixTest.SessionHelpers.scope_selector(session.within, button.selector)}

    cond do
      Button.phx_click?(button) ->
        session.view
        |> element(button.selector, button.text)
        |> render_click()
        |> maybe_redirect(session)

      Button.belongs_to_form?(button) ->
        active_form = session.active_form
        additional_data = FormData.add_data(FormData.new(), button)
        form = Button.parent_form!(button)

        form_data =
          if active_form.selector == form.selector do
            FormData.merge(form.form_data, active_form.form_data)
          else
            form.form_data
          end

        session
        |> Map.put(:active_form, ActiveForm.new())
        |> submit_form(form.selector, form_data, additional_data)

      true ->
        raise ArgumentError, """
        Expected element with selector #{inspect(button.selector)} and text
          #{inspect(button.text)} to have a valid `phx-click` attribute or belong to a `form` element.
        """
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

    field =
      session
      |> render_html()
      |> Select.find_select_option!(input_selector, label, option, opts)

    cond do
      Select.belongs_to_form?(field) ->
        fill_in_field_data(session, field)

      Select.phx_click_options?(field) ->
        Enum.reduce(field.value, session, fn value, session ->
          session.view
          |> element(Select.select_option_selector(field, value))
          |> render_click()
          |> maybe_redirect(session)
        end)

      true ->
        raise ArgumentError, """
        Expected select with selector #{inspect(field.selector)} to have a valid `phx-click` attribute on options or to belong to a `form` element.
        """
    end
  end

  def check(session, label, opts) do
    check(session, "input[type='checkbox']", label, opts)
  end

  def check(session, input_selector, label, opts) do
    field =
      session
      |> render_html()
      |> Field.find_checkbox!(input_selector, label, opts)

    cond do
      Field.phx_click?(field) ->
        session.view
        |> element(field.selector)
        |> render_click()
        |> maybe_redirect(session)

      Field.belongs_to_form?(field) ->
        fill_in_field_data(session, field)

      true ->
        raise ArgumentError, """
        Expected checkbox with selector #{inspect(field.selector)} to have a valid `phx-click` attribute or belong to a `form` element.
        """
    end
  end

  def uncheck(session, label, opts) do
    uncheck(session, "input[type='checkbox']", label, opts)
  end

  def uncheck(session, input_selector, label, opts) do
    html = render_html(session)
    field = Field.find_checkbox!(html, input_selector, label, opts)

    cond do
      # Support phx-click on checkboxes that have phx-value-key attributes too
      Field.phx_click?(field) and Field.phx_value?(field) ->
        session.view
        |> element(field.selector)
        |> render_click()
        |> maybe_redirect(session)

      # Support phx-click on checkboxes that aren't in forms
      Field.phx_click?(field) ->
        event = Html.attribute(field.parsed, "phx-click")

        session.view
        |> render_click(event, %{})
        |> maybe_redirect(session)

      Field.belongs_to_form?(field) ->
        html
        |> Field.find_hidden_uncheckbox!(input_selector, label, opts)
        |> then(&fill_in_field_data(session, &1))

      true ->
        raise ArgumentError, """
        Expected checkbox with selector #{inspect(field.selector)} to have a valid `phx-click` attribute or belong to a `form` element.
        """
    end
  end

  def choose(session, label, opts) do
    choose(session, "input[type='radio']", label, opts)
  end

  def choose(session, input_selector, label, opts) do
    field =
      session
      |> render_html()
      |> Field.find_input!(input_selector, label, opts)

    cond do
      Field.phx_click?(field) ->
        session.view
        |> element(field.selector)
        |> render_click()
        |> maybe_redirect(session)

      Field.belongs_to_form?(field) ->
        fill_in_field_data(session, field)

      true ->
        raise ArgumentError, """
        Expected radio input with selector #{inspect(field.selector)} to have a valid `phx-click` attribute or belong to a `form` element.
        """
    end
  end

  def upload(session, label, path, opts) do
    upload(session, "input[type='file']", label, path, opts)
  end

  def upload(session, input_selector, label, path, opts) do
    field =
      session
      |> render_html()
      |> Field.find_input!(input_selector, label, opts)

    file_stat = File.stat!(path)
    file_name = Path.basename(path)
    form = Field.parent_form!(field)
    live_upload_name = String.to_existing_atom(field.name)
    mime_type = FileUpload.mime_type(path)

    entry = %{
      last_modified: file_stat.mtime,
      name: file_name,
      content: File.read!(path),
      size: file_stat.size,
      type: mime_type
    }

    upload_progress_result =
      session.view
      |> file_input(form.selector, live_upload_name, [entry])
      |> render_upload(file_name)
      |> maybe_throw_upload_errors(session, file_name, live_upload_name)

    session.view
    |> form(form.selector)
    |> render_change(%{"_target" => field.name})
    |> progress_redirect_or_change_result(upload_progress_result, session)
  end

  defp progress_redirect_or_change_result(_change_result, {:error, _} = upload_progress_result, session) do
    maybe_redirect(upload_progress_result, session)
  end

  defp progress_redirect_or_change_result(change_result, _upload_progress_result, session) do
    maybe_redirect(change_result, session)
  end

  defp maybe_throw_upload_errors({:error, [[_id, error]]}, session, file_name, live_upload_name) do
    case error do
      :not_accepted -> raise ArgumentError, message: not_accepted_error_msg(session, file_name, live_upload_name)
      :too_many_files -> raise ArgumentError, message: too_many_files_error_msg(session, file_name, live_upload_name)
      :too_large -> raise ArgumentError, message: too_large_error_msg(session, file_name, live_upload_name)
    end
  end

  defp maybe_throw_upload_errors(session_or_redirect, _session, _file_name, _live_upload_name) do
    session_or_redirect
  end

  defp not_accepted_error_msg(session, file_name, live_upload_name) do
    allowed_list =
      session.conn.assigns.uploads[live_upload_name].acceptable_exts
      |> MapSet.to_list()
      |> Enum.join(", ")

    """
    Unsupported file type.

    You were trying to upload "#{file_name}",
    but the only file types specified in `allow_upload` are [#{allowed_list}].
    """
  end

  defp too_many_files_error_msg(session, file_name, live_upload_name) do
    %{name: name, max_entries: max_entries} = session.conn.assigns.uploads[live_upload_name]

    """
    Too many files uploaded.

    While attempting to upload "#{file_name}", you've exceeded #{max_entries} file(s). If this is intentional,
    consider updating `allow_upload(:#{name}, max_entries: #{max_entries})`.
    """
  end

  defp too_large_error_msg(session, file_name, live_upload_name) do
    %{name: name, max_file_size: max_file_size} = session.conn.assigns.uploads[live_upload_name]

    """
    File too large.

    While attempting to upload "#{file_name}", you've exceeded the maximum file size of #{max_file_size} bytes. If this is intentional,
    consider updating `allow_upload(:#{name}, max_file_size: #{max_file_size})`.
    """
  end

  defp fill_in_field_data(session, field) do
    Field.validate_name!(field)

    form = Field.parent_form!(field)

    session =
      Map.update!(session, :active_form, fn active_form ->
        if active_form.selector == form.selector do
          ActiveForm.add_form_data(session.active_form, field)
        else
          [id: form.id, selector: form.selector]
          |> ActiveForm.new()
          |> ActiveForm.add_form_data(field)
        end
      end)

    if Form.phx_change?(form) do
      active_form = session.active_form
      data_to_submit = FormData.merge(form.form_data, active_form.form_data)
      additional_data = %{"_target" => field.name}

      session.view
      |> form(form.selector, FormPayload.new(data_to_submit))
      |> render_change(additional_data)
      |> maybe_redirect(session)
    else
      session
    end
  end

  def submit(session) do
    active_form = session.active_form

    unless ActiveForm.active?(active_form), do: raise(no_active_form_error())

    selector = active_form.selector

    submit_form(session, selector, active_form.form_data)
  end

  defp no_active_form_error do
    %ArgumentError{
      message: "There's no active form. Fill in a form with `fill_in`, `select`, etc."
    }
  end

  def submit_form(session, selector, form_data, additional_data \\ FormData.new()) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    form_data = remove_data_for_fields_that_have_been_removed(form_data, form)
    form_data = FormData.merge(form.form_data, form_data)

    additional_data =
      if form.submit_button do
        FormData.new()
        |> FormData.add_data(form.submit_button)
        |> FormData.merge(additional_data)
      else
        additional_data
      end

    cond do
      Form.phx_submit?(form) ->
        session.view
        |> form(selector, FormPayload.new(form_data))
        |> render_submit(FormPayload.new(additional_data))
        |> maybe_redirect(session)

      Form.has_action?(form) ->
        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.Static.submit_form(selector, form_data)

      true ->
        raise ArgumentError,
              "Expected form with selector #{inspect(selector)} to have a `phx-submit` or `action` defined."
    end
  end

  defp remove_data_for_fields_that_have_been_removed(form_data, form) do
    element_names = Form.form_element_names(form)

    FormData.filter(form_data, fn %{name: name} ->
      name in element_names
    end)
  end

  def open_browser(%{view: view} = session, open_fun \\ &Phoenix.LiveViewTest.open_browser/1) do
    open_fun.(view)
    session
  end

  def unwrap(%{view: view} = session, fun) when is_function(fun, 1) do
    view
    |> fun.()
    |> maybe_redirect(session)
  end

  def assert_has(session, selector, opts) when is_list(opts) do
    {timeout, opts} = Keyword.pop(opts, :timeout, 0)

    LiveViewTimeout.with_timeout(session, timeout, fn session ->
      Assertions.assert_has(session, selector, opts)
    end)
  end

  def refute_has(session, selector, opts) when is_list(opts) do
    {timeout, opts} = Keyword.pop(opts, :timeout, 0)

    LiveViewTimeout.with_timeout(session, timeout, fn session ->
      Assertions.refute_has(session, selector, opts)
    end)
  end

  def handle_redirect(session, redirect_tuple) do
    maybe_redirect({:error, redirect_tuple}, session)
  end

  defp maybe_redirect({:error, {kind, %{to: path}}} = result, session) when kind in [:redirect, :live_redirect] do
    session = %{session | current_path: path}
    conn = session.conn

    result
    |> follow_redirect(ConnHandler.recycle_all_headers(conn))
    |> maybe_redirect(session)
  end

  defp maybe_redirect({:ok, view, _}, session) do
    %{session | view: view}
  end

  defp maybe_redirect({:ok, conn}, _session) do
    ConnHandler.visit(conn)
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    case Form.find(html, "form[phx-trigger-action]") do
      :not_found ->
        maybe_put_patch_path(session)

      {:found, form} ->
        active_form = session.active_form
        active_form? = form.selector == active_form.selector
        form_data = FormData.merge(form.form_data, if(active_form?, do: active_form.form_data, else: FormData.new()))

        %{session.conn | resp_body: html}
        |> PhoenixTest.Static.build()
        |> PhoenixTest.Static.submit_form(form.selector, form_data)

      {:found_many, _} ->
        raise ArgumentError, "Found multiple forms with phx-trigger-action."
    end
  end

  defp maybe_put_patch_path(session) do
    case fetch_patch_path(session.view) do
      :no_path ->
        session

      path when is_binary(path) ->
        %{session | current_path: path}
    end
  end

  defp fetch_patch_path(view) do
    assert_patch(view, 0)
  rescue
    ArgumentError -> :no_path
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  alias PhoenixTest.Assertions
  alias PhoenixTest.ConnHandler
  alias PhoenixTest.Live
  alias PhoenixTest.SessionHelpers

  def visit(session, path) do
    ConnHandler.visit(session.conn, path)
  end

  defdelegate render_page_title(session), to: Live
  defdelegate render_html(session), to: Live
  defdelegate click_link(session, text), to: Live
  defdelegate click_link(session, selector, text), to: Live
  defdelegate click_button(session, text), to: Live
  defdelegate click_button(session, selector, text), to: Live
  defdelegate within(session, selector, fun), to: SessionHelpers
  defdelegate fill_in(session, label, opts), to: Live
  defdelegate fill_in(session, input_selector, label, opts), to: Live
  defdelegate select(session, option, opts), to: Live
  defdelegate select(session, input_selector, option, opts), to: Live
  defdelegate check(session, label, opts), to: Live
  defdelegate check(session, input_selector, label, opts), to: Live
  defdelegate uncheck(session, label, opts), to: Live
  defdelegate uncheck(session, input_selector, label, opts), to: Live
  defdelegate choose(session, label, opts), to: Live
  defdelegate choose(session, input_selector, label, opts), to: Live
  defdelegate upload(session, label, path, opts), to: Live
  defdelegate upload(session, input_selector, label, path, opts), to: Live
  defdelegate submit(session), to: Live
  defdelegate open_browser(session), to: Live
  defdelegate open_browser(session, open_fun), to: Live
  defdelegate unwrap(session, fun), to: Live
  defdelegate current_path(session), to: Live

  defdelegate assert_has(session, selector), to: Assertions
  defdelegate assert_has(session, selector, opts), to: Live
  defdelegate refute_has(session, selector), to: Assertions
  defdelegate refute_has(session, selector, opts), to: Live
  defdelegate assert_path(session, path), to: Assertions
  defdelegate assert_path(session, path, opts), to: Assertions
  defdelegate refute_path(session, path), to: Assertions
  defdelegate refute_path(session, path, opts), to: Assertions
end
