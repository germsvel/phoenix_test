defmodule PhoenixTest.Wallaby do
  @moduledoc false

  import Wallaby.Browser

  alias ExUnit.AssertionError
  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Html
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Query

  require Wallaby.Browser

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct session: nil, within: :none, last_field_query: :none

  def build(_conn, path) do
    {:ok, session} = Wallaby.start_session()
    Wallaby.Browser.visit(session, path)
    %__MODULE__{session: session}
  end

  def current_path(%{session: session}) do
    uri = session |> current_url() |> URI.parse()
    append_query_string(uri.path, uri.query)
  end

  def append_query_string(path, nil), do: path
  def append_query_string(path, query), do: path <> "?" <> query

  def render_page_title(session) do
    session
    |> render_html()
    |> Query.find("title")
    |> case do
      {:found, element} -> Html.text(element)
      _ -> nil
    end
  end

  def render_html(%{session: session, within: within}) do
    html = Wallaby.Browser.page_source(session)

    case within do
      :none -> html
      selector -> html |> Query.find!(selector) |> Html.raw()
    end
  end

  def click_link(session, selector \\ "a", text) do
    click(session, selector, text)
  end

  def click_button(session, selector \\ "button", text) do
    belongs_to_form? =
      session
      |> render_html()
      |> Button.find!(selector, text)
      |> Button.belongs_to_form?()

    session
    |> click(selector, text)
    |> Map.update!(:last_field_query, &if(belongs_to_form?, do: :none, else: &1))
  end

  defp click(session, selector, text) do
    Wallaby.Browser.click(session.session, Wallaby.Query.css(selector, text: text))

    session
  end

  def within(session, selector, fun) when is_function(fun, 1) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, label, with: value) do
    field = Field.find_input!(render_html(session), label)
    query = query(session, label, &Field.find_input!/2)

    case Html.attribute(field.raw, "type") do
      # Set via JS to avoid locale format issues
      type when type in ~w(date datetime-local time week) ->
        js = """
          el = document.querySelector('#{field.selector}');
          el.value = '#{value}';
        """

        session.session
        |> Wallaby.Browser.execute_script(js)
        |> Wallaby.Browser.click(query)

      _other ->
        Wallaby.Browser.clear(session.session, query)
        unless is_nil(value), do: Wallaby.Browser.fill_in(session.session, query, with: value)
    end

    session
    |> Map.put(:last_field_query, query)
    |> trigger_phx_change_validations(query)
  end

  def select(session, options, from: label) do
    query = query(session, label, &Field.find_input!/2)

    for option <- List.wrap(options) do
      session.session
      |> Wallaby.Browser.find(query)
      |> Wallaby.Browser.set_value(Wallaby.Query.css("option", text: option), :selected)
    end

    Map.put(session, :last_field_query, query)
  end

  def check(session, label) do
    query = query(session, label, &Field.find_checkbox!/2)
    Wallaby.Browser.set_value(session.session, query, :selected)

    Map.put(session, :last_field_query, query)
  end

  def uncheck(session, label) do
    query = query(session, label, &Field.find_checkbox!/2)
    Wallaby.Browser.set_value(session.session, query, :unselected)

    Map.put(session, :last_field_query, query)
  end

  def choose(session, label) do
    query = query(session, label, &Field.find_input!/2)
    Wallaby.Browser.click(session.session, query)

    Map.put(session, :last_field_query, query)
  end

  def submit(session) do
    case session.last_field_query do
      :none -> raise no_active_form_error()
      query -> Wallaby.Browser.send_keys(session.session, query, [:enter])
    end

    Map.put(session, :last_field_query, :none)
  end

  def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])

    html =
      session.session
      |> Wallaby.Browser.page_source()
      |> Floki.parse_document!()
      |> Floki.traverse_and_update(&OpenBrowser.prefix_static_paths(&1, @endpoint))
      |> Floki.raw_html()

    File.write!(path, html)

    open_fun.(path)

    session
  end

  def unwrap(session, fun) when is_function(fun, 1) do
    fun.(session.session)
    session
  end

  defp query(session, label, find_fun) do
    # Use PhoenixTest.Field queries for label exact-match semantics
    html = render_html(session)
    field = find_fun.(html, label)

    within =
      case session.within do
        :none -> ""
        selector -> selector
      end

    selector = "#{within} #{field.selector}"
    Query.find!(html, selector)
    Wallaby.Query.css(selector)
  end

  defp trigger_phx_change_validations(session, query) do
    if has?(session.session, query) do
      Wallaby.Browser.send_keys(session.session, query, [:tab])
    end

    session
  end

  defp no_active_form_error do
    %ArgumentError{
      message: "There's no active form. Fill in a form with `fill_in`, `select`, etc."
    }
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Wallaby do
  alias ExUnit.AssertionError
  alias PhoenixTest.Assertions
  alias PhoenixTest.Wallaby

  def render_page_title(session), do: map_errors(fn -> Wallaby.render_page_title(session) end)
  def render_html(session), do: map_errors(fn -> Wallaby.render_html(session) end)
  def click_link(session, text), do: map_errors(fn -> Wallaby.click_link(session, text) end)
  def click_link(session, selector, text), do: map_errors(fn -> Wallaby.click_link(session, selector, text) end)
  def click_button(session, text), do: map_errors(fn -> Wallaby.click_button(session, text) end)
  def click_button(session, selector, text), do: map_errors(fn -> Wallaby.click_button(session, selector, text) end)
  def within(session, selector, fun), do: map_errors(fn -> Wallaby.within(session, selector, fun) end)
  def fill_in(session, label, attrs), do: map_errors(fn -> Wallaby.fill_in(session, label, attrs) end)
  def select(session, option, attrs), do: map_errors(fn -> Wallaby.select(session, option, attrs) end)
  def check(session, label), do: map_errors(fn -> Wallaby.check(session, label) end)
  def uncheck(session, label), do: map_errors(fn -> Wallaby.uncheck(session, label) end)
  def choose(session, label), do: map_errors(fn -> Wallaby.choose(session, label) end)
  def submit(session), do: map_errors(fn -> Wallaby.submit(session) end)
  def open_browser(session), do: map_errors(fn -> Wallaby.open_browser(session) end)
  def open_browser(session, open_fun), do: map_errors(fn -> Wallaby.open_browser(session, open_fun) end)
  def unwrap(session, fun), do: map_errors(fn -> Wallaby.unwrap(session, fun) end)
  def current_path(session), do: map_errors(fn -> Wallaby.current_path(session) end)

  def assert_has(session, selector), do: retry(fn -> Assertions.assert_has(session, selector) end)
  def assert_has(session, selector, opts), do: retry(fn -> Assertions.assert_has(session, selector, opts) end)
  def refute_has(session, selector), do: retry(fn -> Assertions.refute_has(session, selector) end)
  def refute_has(session, selector, opts), do: retry(fn -> Assertions.refute_has(session, selector, opts) end)
  def assert_path(session, path), do: retry(fn -> Assertions.assert_path(session, path) end)
  def assert_path(session, path, opts), do: retry(fn -> Assertions.assert_path(session, path, opts) end)
  def refute_path(session, path), do: retry(fn -> Assertions.refute_path(session, path) end)
  def refute_path(session, path, opts), do: retry(fn -> Assertions.refute_path(session, path, opts) end)

  defp map_errors(fun) do
    fun.()
  rescue
    e ->
      raise ArgumentError, e.message
  end

  defp retry(fun, timeout_ms \\ 300, interval_ms \\ 10) do
    now = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    timeout_at = DateTime.utc_now() |> DateTime.add(timeout_ms, :millisecond) |> DateTime.to_unix(:millisecond)
    retry(fun, now, timeout_at, interval_ms)
  end

  defp retry(fun, now, timeout_at, _interval_ms) when now >= timeout_at do
    fun.()
  end

  defp retry(fun, _now, timeout_at, interval_ms) do
    fun.()
  rescue
    AssertionError ->
      Process.sleep(interval_ms)
      now = DateTime.to_unix(DateTime.utc_now(), :millisecond)
      retry(fun, now, timeout_at, interval_ms)
  end
end
