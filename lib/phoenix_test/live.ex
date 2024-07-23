defmodule PhoenixTest.Live do
  @moduledoc false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.Query

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

  def click_link(session, text) do
    click_link(session, "a", text)
  end

  def click_link(session, selector, text) do
    session.view
    |> element(selector, text)
    |> render_click()
    |> maybe_redirect(session)
  end

  def click_button(session, text) do
    click_button(session, "button", text)
  end

  def click_button(session, selector, text) do
    active_form = session.active_form
    html = render_html(session)
    button = Button.find!(html, selector, text)

    cond do
      Button.phx_click?(button) ->
        session.view
        |> element(selector, text)
        |> render_click()
        |> maybe_redirect(session)

      Button.belongs_to_form?(button) ->
        additional_data = Button.to_form_data(button)
        form = Button.parent_form!(button)

        form_data =
          if active_form.selector == form.selector do
            active_form.form_data
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

  def fill_in(session, label, with: value) do
    session
    |> render_html()
    |> Field.find_input!(label)
    |> Map.put(:value, to_string(value))
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
        existing_data ++ new_form_data
      else
        new_form_data
      end

    additional_data = %{"_target" => field.name}

    fill_form(session, form.selector, form_data, additional_data)
  end

  defp fill_form(session, selector, form_data, additional_data) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    active_form =
      [id: form.id, selector: form.selector]
      |> ActiveForm.new()
      |> ActiveForm.prepend_form_data(form.form_data)
      |> ActiveForm.add_form_data(form_data)

    session = Map.put(session, :active_form, active_form)

    if Form.phx_change?(form) do
      session.view
      |> form(selector, Form.build_data(active_form.form_data))
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

    form =
      session
      |> render_html()
      |> Form.find!(selector)

    additional_data =
      if form.submit_button do
        Button.to_form_data(form.submit_button)
      else
        []
      end

    form_data = form.form_data ++ active_form.form_data

    cond do
      Form.phx_submit?(form) ->
        session.view
        |> form(selector, Form.build_data(form_data))
        |> render_submit(Form.build_data(additional_data))
        |> maybe_redirect(session)

      Form.has_action?(form) ->
        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.Static.fill_form(selector, form_data)
        |> PhoenixTest.submit()

      true ->
        raise ArgumentError,
              "Expected form with selector #{inspect(selector)} to have a `phx-submit` or `action` defined."
    end
  end

  defp no_active_form_error do
    %ArgumentError{
      message: "There's no active form. Fill in a form with `fill_in`, `select`, etc."
    }
  end

  def submit_form(session, selector, form_data, event_data) do
    form =
      session
      |> render_html()
      |> Form.find!(selector)

    form_data = form.form_data ++ form_data

    cond do
      Form.phx_submit?(form) ->
        session.view
        |> form(selector, Form.build_data(form_data))
        |> render_submit(Form.build_data(event_data))
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
    maybe_put_patch_path(session)
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
  defdelegate click_link(session, text), to: Live
  defdelegate click_link(session, selector, text), to: Live
  defdelegate click_button(session, text), to: Live
  defdelegate click_button(session, selector, text), to: Live
  defdelegate within(session, selector, fun), to: Live
  defdelegate fill_in(session, label, attrs), to: Live
  defdelegate select(session, option, attrs), to: Live
  defdelegate check(session, label), to: Live
  defdelegate uncheck(session, label), to: Live
  defdelegate choose(session, label), to: Live
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
