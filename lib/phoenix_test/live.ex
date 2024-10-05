defmodule PhoenixTest.Live do
  @moduledoc false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.FileUpload
  alias PhoenixTest.Form
  alias PhoenixTest.FormData
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Select

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct view: nil, conn: nil, active_form: ActiveForm.new(), within: :none, current_path: ""

  def build(conn) do
    {:ok, view, _html} = live(conn)
    current_path = append_query_string(conn.request_path, conn.query_string)
    %__MODULE__{view: view, conn: conn, current_path: current_path}
  end

  def current_path(session), do: session.current_path

  defp append_query_string(path, ""), do: path
  defp append_query_string(path, query), do: path <> "?" <> query

  def render_page_title(%{view: view}) do
    page_title(view)
  end

  def render_html(%{view: view, within: within}) do
    case within do
      :none ->
        render(view)

      selector ->
        view
        |> render()
        |> Query.find!(selector)
        |> Html.raw()
    end
  end

  def click_link(session, selector, text) do
    session.view
    |> element(selector, text)
    |> render_click()
    |> maybe_redirect(session)
  end

  def click_button(session, selector, text) do
    html = render_html(session)
    button = Button.find!(html, selector, text)

    cond do
      Button.phx_click?(button) ->
        session.view
        |> element(selector, text)
        |> render_click()
        |> maybe_redirect(session)

      Button.belongs_to_form?(button) ->
        active_form = session.active_form
        additional_data = Button.to_form_data(button)
        form = Button.parent_form!(button)

        form_data =
          if active_form.selector == form.selector do
            form.form_data ++ active_form.form_data
          else
            form.form_data
          end

        session
        |> Map.put(:active_form, ActiveForm.new())
        |> submit_form(form.selector, form_data, additional_data)

      true ->
        raise ArgumentError, """
        Expected element with selector #{inspect(selector)} and text #{inspect(text)} to have a `phx-click` attribute or belong to a `form` element.
        """
    end
  end

  def within(session, selector, fun) when is_function(fun, 1) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, input_selector, label, opts) do
    {value, opts} = Keyword.pop!(opts, :with)

    session
    |> render_html()
    |> Field.find_input!(input_selector, label, opts)
    |> Map.put(:value, to_string(value))
    |> then(&fill_in_field_data(session, &1))
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
        Expected select with selector #{inspect(field.selector)} to have a `phx-click` attribute on options or to belong to a `form` element.
        """
    end
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
        Expected checkbox with selector #{inspect(field.selector)} to have a `phx-click` attribute or belong to a `form` element.
        """
    end
  end

  def uncheck(session, input_selector, label, opts) do
    html = render_html(session)
    field = Field.find_checkbox!(html, input_selector, label, opts)

    cond do
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
        Expected checkbox with selector #{inspect(field.selector)} to have a `phx-click` attribute or belong to a `form` element.
        """
    end
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
        Expected radio input with selector #{inspect(field.selector)} to have a `phx-click` attribute or belong to a `form` element.
        """
    end
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

    session.view
    |> file_input(form.selector, live_upload_name, [entry])
    |> render_upload(file_name)
    |> maybe_redirect(session)
  end

  defp fill_in_field_data(session, field) do
    new_form_data = FormData.to_form_data!(field)
    form = Field.parent_form!(field)

    session =
      Map.update!(session, :active_form, fn active_form ->
        if active_form.selector == form.selector do
          ActiveForm.add_form_data(session.active_form, new_form_data)
        else
          ActiveForm.new(id: form.id, form_data: new_form_data, selector: form.selector)
        end
      end)

    if Form.phx_change?(form) do
      active_form = session.active_form
      data_to_submit = form.form_data ++ active_form.form_data
      additional_data = %{"_target" => field.name}

      session.view
      |> form(form.selector, Form.build_data(data_to_submit))
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

  def submit_form(session, selector, form_data, additional_data \\ []) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    form_data = form.form_data ++ form_data

    additional_data =
      if form.submit_button do
        Button.to_form_data(form.submit_button) ++ additional_data
      else
        additional_data
      end

    cond do
      Form.phx_submit?(form) ->
        session.view
        |> form(selector, Form.build_data(form_data))
        |> render_submit(Form.build_data(additional_data))
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

  def open_browser(%{view: view} = session, open_fun \\ &Phoenix.LiveViewTest.open_browser/1) do
    open_fun.(view)
    session
  end

  def unwrap(%{view: view} = session, fun) when is_function(fun, 1) do
    view
    |> fun.()
    |> maybe_redirect(session)
  end

  defp maybe_redirect({:error, {:redirect, %{to: path}}}, session) do
    PhoenixTest.visit(session.conn, path)
  end

  defp maybe_redirect({:error, {:live_redirect, %{to: path}}} = result, session) do
    session = %{session | current_path: path}

    result
    |> follow_redirect(session.conn)
    |> maybe_redirect(session)
  end

  defp maybe_redirect({:ok, view, _}, session) do
    %{session | view: view}
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    case Form.find(html, "form[phx-trigger-action]") do
      :not_found ->
        maybe_put_patch_path(session)

      {:found, form} ->
        active_form = session.active_form
        active_form? = form.selector == active_form.selector
        form_data = form.form_data ++ if(active_form?, do: active_form.form_data, else: [])

        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.Static.submit_form(form.selector, form_data)

      {:found_many, _} ->
        raise raise ArgumentError, "Found multiple forms with phx-trigger-action."
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
  alias PhoenixTest.Live

  defdelegate render_page_title(session), to: Live
  defdelegate render_html(session), to: Live
  defdelegate click_link(session, selector, text), to: Live
  defdelegate click_button(session, selector, text), to: Live
  defdelegate within(session, selector, fun), to: Live
  defdelegate fill_in(session, input_selector, label, opts), to: Live
  defdelegate select(session, input_selector, option, opts), to: Live
  defdelegate check(session, input_selector, label, opts), to: Live
  defdelegate uncheck(session, input_selector, label, opts), to: Live
  defdelegate choose(session, input_selector, label, opts), to: Live
  defdelegate upload(session, input_selector, label, path, opts), to: Live
  defdelegate submit(session), to: Live
  defdelegate open_browser(session), to: Live
  defdelegate open_browser(session, open_fun), to: Live
  defdelegate unwrap(session, fun), to: Live
  defdelegate current_path(session), to: Live

  defdelegate assert_has(session, selector), to: Assertions
  defdelegate assert_has(session, selector, opts), to: Assertions
  defdelegate refute_has(session, selector), to: Assertions
  defdelegate refute_has(session, selector, opts), to: Assertions
  defdelegate assert_path(session, path), to: Assertions
  defdelegate assert_path(session, path, opts), to: Assertions
  defdelegate refute_path(session, path), to: Assertions
  defdelegate refute_path(session, path, opts), to: Assertions
end
