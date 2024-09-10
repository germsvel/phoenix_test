defmodule PhoenixTest.Playwright do
  @moduledoc false

  alias ExUnit.AssertionError
  alias PhoenixTest.Html
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Query

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  defstruct page: nil, within: :none, last_field_query: :none

  def build(_conn, path, browser_name) do
    {:ok, browser} = Playwright.launch(browser_name)
    page = Playwright.Browser.new_page(browser)
    Playwright.Page.goto(page, @endpoint.url() <> path)

    %__MODULE__{page: page}
  end

  def current_path(%{page: _page}) do
    raise "not implemented"
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

  def render_html(%{page: page, within: within}) do
    selector =
      case within do
        :none -> "html"
        other -> other
      end

    page
    |> Playwright.Page.locator(selector)
    |> Playwright.Locator.inner_html()
  end

  def click_link(_session, _selector \\ "a", _text) do
    raise "not implemented"
    # click(session, selector, text)
  end

  def click_button(_session, _selector \\ "button", _text) do
    raise "not implemented"
  end

  def within(session, selector, fun) when is_function(fun, 1) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(_session, _label, with: _value) do
    raise "not implemented"
  end

  def select(_session, _options, from: _label) do
    raise "not implemented"
  end

  def check(_session, _label) do
    raise "not implemented"
  end

  def uncheck(_session, _label) do
    raise "not implemented"
  end

  def choose(_session, _label) do
    raise "not implemented"
  end

  def submit(_session) do
    raise "not implemented"
  end

  def open_browser(_session, _open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    raise "not implemented"
  end

  def unwrap(session, fun) when is_function(fun, 1) do
    fun.(session.session)
    session
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Playwright do
  alias ExUnit.AssertionError
  alias PhoenixTest.Assertions
  alias PhoenixTest.Playwright

  defdelegate render_page_title(session), to: Playwright
  defdelegate render_html(session), to: Playwright
  defdelegate click_link(session, text), to: Playwright
  defdelegate click_link(session, selector, text), to: Playwright
  defdelegate click_button(session, text), to: Playwright
  defdelegate click_button(session, selector, text), to: Playwright
  defdelegate within(session, selector, fun), to: Playwright
  defdelegate fill_in(session, label, attrs), to: Playwright
  defdelegate select(session, option, attrs), to: Playwright
  defdelegate check(session, label), to: Playwright
  defdelegate uncheck(session, label), to: Playwright
  defdelegate choose(session, label), to: Playwright
  defdelegate submit(session), to: Playwright
  defdelegate open_browser(session), to: Playwright
  defdelegate open_browser(session, open_fun), to: Playwright
  defdelegate unwrap(session, fun), to: Playwright
  defdelegate current_path(session), to: Playwright

  def assert_has(session, selector), do: retry(fn -> Assertions.assert_has(session, selector) end)
  def assert_has(session, selector, opts), do: retry(fn -> Assertions.assert_has(session, selector, opts) end)
  def refute_has(session, selector), do: retry(fn -> Assertions.refute_has(session, selector) end)
  def refute_has(session, selector, opts), do: retry(fn -> Assertions.refute_has(session, selector, opts) end)
  def assert_path(session, path), do: retry(fn -> Assertions.assert_path(session, path) end)
  def assert_path(session, path, opts), do: retry(fn -> Assertions.assert_path(session, path, opts) end)
  def refute_path(session, path), do: retry(fn -> Assertions.refute_path(session, path) end)
  def refute_path(session, path, opts), do: retry(fn -> Assertions.refute_path(session, path, opts) end)

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
