defmodule PhoenixTest.Live do
  @moduledoc false
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  defstruct view: nil, conn: nil, private: %{}

  def build(conn) do
    {:ok, view, _html} = live(conn)
    %__MODULE__{view: view, conn: conn}
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

  def put_private(%{private: private} = session, key, value) do
    new_private = Map.put(private, key, value)

    %{session | private: new_private}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixTest.Field
  alias PhoenixTest.Html
  alias PhoenixTest.Query

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
    {form, session} = PhoenixTest.Live.pop_private(session, :active_form)

    if has_active_form?(form) and is_submit_button?(form.form_element, selector, text) do
      submit_form(session, form.selector, form.form_data)
    else
      session.view
      |> element(selector, text)
      |> render_click()
      |> maybe_redirect(session)
    end
  end

  defp is_submit_button?(form_element, selector, text) do
    submit_buttons = ["input[type=submit][value=#{text}]", {selector, text}]

    form_element
    |> Html.raw()
    |> Query.find_one_of(submit_buttons)
    |> case do
      {:found, _} ->
        true

      {:found_many, elements} ->
        msg = """
        Found too many submit buttons (#{Enum.count(elements)}) with text #{inspect(text)}:

        #{Enum.map_join(elements, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      {:not_found, _} ->
        false
    end
  end

  defp has_active_form?(%{form_data: _}), do: true
  defp has_active_form?(%{}), do: false

  def fill_in(session, label, with: value) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label, value)

    new_form_data = Field.to_form_data(field)
    active_form = add_to_active_form_data(session, new_form_data)

    form = Field.parent_form(field)

    session
    |> PhoenixTest.Live.put_private(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def select(session, option, from: label) do
    field =
      session
      |> render_html()
      |> Field.find_select_option!(label, option)

    new_form_data = Field.to_form_data(field)
    active_form = add_to_active_form_data(session, new_form_data)

    form = Field.parent_form(field)

    session
    |> PhoenixTest.Live.put_private(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def check(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_checkbox!(label)

    new_form_data = Field.to_form_data(field)
    active_form = add_to_active_form_data(session, new_form_data)

    form = Field.parent_form(field)

    session
    |> PhoenixTest.Live.put_private(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def uncheck(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_hidden_uncheckbox!(label)

    new_form_data = Field.to_form_data(field)
    active_form = add_to_active_form_data(session, new_form_data)

    form = Field.parent_form(field)

    session
    |> PhoenixTest.Live.put_private(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  def choose(session, label) do
    field =
      session
      |> render_html()
      |> Field.find_input!(label)

    new_form_data = Field.to_form_data(field)
    active_form = add_to_active_form_data(session, new_form_data)

    form = Field.parent_form(field)

    session
    |> PhoenixTest.Live.put_private(:active_form, active_form)
    |> fill_form("form##{form.id}", active_form.form_data)
  end

  defp add_to_active_form_data(session, new_form_data) do
    session
    |> PhoenixTest.Live.get_private(:active_form, %{form_data: %{}})
    |> Map.update(:form_data, %{}, fn form_data ->
      DeepMerge.deep_merge(form_data, new_form_data)
    end)
  end

  def fill_form(session, selector, form_data) do
    form_element =
      session
      |> render_html()
      |> Query.find!(selector)

    if phx_change_form?(form_element) do
      session.view
      |> form(selector, form_data)
      |> render_change()
    else
      form_element
      |> Html.Form.build()
      |> then(fn form ->
        :ok = Html.Form.validate_form_fields!(form["fields"], form_data)
      end)
    end

    session
    |> PhoenixTest.Live.put_private(:active_form, %{
      selector: selector,
      form_data: form_data,
      form_element: form_element
    })
  end

  def submit_form(session, selector, form_data) do
    form_element =
      session
      |> render_html()
      |> Query.find!(selector)

    cond do
      phx_submit_form?(form_element) ->
        session.view
        |> form(selector, form_data)
        |> render_submit()
        |> maybe_redirect(session)

      action_form?(form_element) ->
        session.conn
        |> PhoenixTest.Static.build()
        |> PhoenixTest.submit_form(selector, form_data)

      true ->
        raise ArgumentError,
              "Expected form with selector #{inspect(selector)} to have a `phx-submit` or `action` defined."
    end
  end

  defp action_form?(form_element) do
    action = Html.attribute(form_element, "action")

    action != nil && action != ""
  end

  defp phx_submit_form?(form_element) do
    phx_submit = Html.attribute(form_element, "phx-submit")

    phx_submit != nil && phx_submit != ""
  end

  defp phx_change_form?(form_element) do
    phx_change = Html.attribute(form_element, "phx-change")

    phx_change != nil && phx_change != ""
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
