defmodule PhoenixTest.Live do
  @moduledoc false
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.ActiveForm

  defstruct view: nil, conn: nil, active_form: ActiveForm.new()

  def build(conn) do
    {:ok, view, _html} = live(conn)
    %__MODULE__{view: view, conn: conn}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Form
  alias PhoenixTest.Html

  def render_page_title(%{view: view}) do
    page_title(view)
  end

  def render_html(%{view: view}) do
    render(view)
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

      Button.belongs_to_form?(button, html) ->
        additional_data = Button.to_form_data(button)
        form = Form.find_by_button!(html, button)

        form_data =
          if active_form.id == form.id do
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

  def fill_in(session, label, with: value) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label, value)

    new_form_data = Field.to_form_data(field)

    active_form = ActiveForm.add_form_data(session.active_form, new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def select(session, option, from: label) do
    field =
      session
      |> render_html()
      |> Field.find_select_option!(label, option)

    new_form_data = Field.to_form_data(field)

    active_form = ActiveForm.add_form_data(session.active_form, new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def check(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_checkbox!(label)

    new_form_data = Field.to_form_data(field)

    active_form = ActiveForm.add_form_data(session.active_form, new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def uncheck(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_hidden_uncheckbox!(label)

    new_form_data = Field.to_form_data(field)

    active_form = ActiveForm.add_form_data(session.active_form, new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def choose(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label)

    new_form_data = Field.to_form_data(field)

    active_form = ActiveForm.add_form_data(session.active_form, new_form_data)

    form = Field.parent_form(field)

    session
    |> Map.put(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def fill_form(session, selector, form_data) do
    form_data = Map.new(form_data, fn {k, v} -> {to_string(k), v} end)

    form =
      session
      |> render_html()
      |> Form.find!(selector)

    active_form =
      session.active_form
      |> Map.put(:id, form.id)
      |> ActiveForm.prepend_form_data(form.form_data)
      |> ActiveForm.add_form_data(form_data)

    if Form.phx_change?(form) do
      session.view
      |> form(selector, active_form.form_data)
      |> render_change()
    else
      form.parsed
      |> Html.Form.build()
      |> then(fn form ->
        :ok = Html.Form.validate_form_fields!(form["fields"], form_data)
      end)
    end

    session
    |> Map.put(:active_form, active_form)
  end

  def submit_form(session, selector, form_data, event_data \\ %{}) do
    form_data = Map.new(form_data, fn {k, v} -> {to_string(k), v} end)

    form =
      session
      |> render_html()
      |> Form.find!(selector)

    form = update_in(form.form_data, fn data -> Map.merge(data, form_data) end)

    cond do
      Form.phx_submit?(form) ->
        session.view
        |> form(selector, form.form_data)
        |> render_submit(event_data)
        |> maybe_redirect(session)

      Form.has_action?(form) ->
        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.submit_form(selector, form.form_data)

      true ->
        raise ArgumentError,
              "Expected form with selector #{inspect(selector)} to have a `phx-submit` or `action` defined."
    end
  end

  def open_browser(%{view: view} = session, open_fun \\ &Phoenix.LiveViewTest.open_browser/1) do
    open_fun.(view)
    session
  end

  defp maybe_redirect({:error, {:redirect, %{to: path}}}, session) do
    PhoenixTest.visit(session.conn, path)
  end

  defp maybe_redirect({:error, {:live_redirect, _}} = result, session) do
    {:ok, view, _} = follow_redirect(result, session.conn)
    %{session | view: view}
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    session
  end
end
