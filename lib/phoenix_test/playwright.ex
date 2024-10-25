defmodule PhoenixTest.Playwright do
  @moduledoc false

  alias PhoenixTest.Assertions
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Link
  alias PhoenixTest.OpenBrowser
  alias PhoenixTest.Playwright.Connection
  alias PhoenixTest.Playwright.Frame
  alias PhoenixTest.Playwright.Selector
  alias PhoenixTest.Query

  defstruct [:frame_id, :last_input_selector, within: :none]

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  @default_timeout :timer.seconds(1)

  def build(frame_id) do
    %__MODULE__{frame_id: frame_id}
  end

  def retry(fun, backoff_ms \\ [100, 250, 500, 1000])
  def retry(fun, []), do: fun.()

  def retry(fun, [sleep_ms | backoff_ms]) do
    fun.()
  rescue
    ExUnit.AssertionError ->
      Process.sleep(sleep_ms)
      retry(fun, backoff_ms)
  end

  def visit(session, path) do
    base_url = Application.fetch_env!(:phoenix_test, :base_url)
    Frame.goto(session.frame_id, base_url <> path)
    session
  end

  def assert_has(session, "title") do
    retry(fn -> Assertions.assert_has(session, "title") end)
  end

  def assert_has(session, selector), do: assert_has(session, selector, [])

  def assert_has(session, "title", opts) do
    retry(fn -> Assertions.assert_has(session, "title", opts) end)
  end

  def assert_has(session, selector, opts) do
    unless found?(session, selector, opts) do
      Assertions.assert_has(session, selector, opts)
    end

    session
  end

  def refute_has(session, "title") do
    retry(fn -> Assertions.refute_has(session, "title") end)
  end

  def refute_has(session, selector), do: refute_has(session, selector, [])

  def refute_has(session, "title", opts) do
    retry(fn -> Assertions.refute_has(session, "title", opts) end)
  end

  def refute_has(session, selector, opts) do
    if found?(session, selector, opts) do
      Assertions.refute_has(session, selector, opts)
    end

    session
  end

  defp found?(session, selector, opts) do
    if opts[:count] && opts[:at] do
      raise ArgumentError, message: "Options `count` and `at` can not be used together."
    end

    selector =
      session
      |> maybe_within()
      |> Selector.concat(Selector.css_or_locator(selector))
      |> Selector.concat(Selector.text(opts[:text], opts))
      |> Selector.concat(Selector.at(opts[:at]))

    if opts[:count] do
      params =
        %{
          expression: "to.have.count",
          expectedNumber: opts[:count],
          state: "attached",
          isNot: false,
          selector: selector,
          timeout: timeout(opts)
        }

      {:ok, found?} = Frame.expect(session.frame_id, params)
      found?
    else
      params =
        %{
          # Consistent with PhoenixTest: ignore visiblity
          state: "attached",
          selector: selector,
          timeout: timeout(opts)
        }

      case Frame.wait_for_selector(session.frame_id, params) do
        {:ok, _} -> true
        _ -> false
      end
    end
  end

  def render_page_title(session) do
    case Frame.title(session.frame_id) do
      {:ok, ""} -> nil
      {:ok, title} -> title
    end
  end

  def render_html(session) do
    selector = maybe_within(session)
    {:ok, html} = Frame.inner_html(session.frame_id, selector)
    html
  end

  def click_link(session, css_selector, text) do
    selector =
      session
      |> maybe_within()
      |> Selector.concat(Selector.css_or_locator(css_selector))
      |> Selector.concat(Selector.text(text, exact: false))

    session.frame_id
    |> Frame.click(selector, %{timeout: timeout()})
    |> handle_response(fn -> Link.find!(render_html(session), css_selector, text) end)

    session
  end

  def click_button(session, css_selector, text) do
    selector =
      session
      |> maybe_within()
      |> Selector.concat(Selector.css_or_locator(css_selector))
      |> Selector.concat(Selector.text(text, exact: false))

    session.frame_id
    |> Frame.click(selector, %{timeout: timeout()})
    |> handle_response(fn -> Button.find!(render_html(session), css_selector, text) end)

    session
  end

  def within(session, selector, fun) do
    session
    |> Map.put(:within, selector)
    |> fun.()
    |> Map.put(:within, :none)
  end

  def fill_in(session, input_selector, label, opts) do
    {value, opts} = Keyword.pop!(opts, :with)
    fun = &Frame.fill(session.frame_id, &1, to_string(value), &2)
    input(session, input_selector, label, opts, fun)
  end

  def select(session, input_selector, option_labels, opts) do
    # TODO Support exact_option
    if opts[:exact_option] != true, do: raise("exact_option not implemented")

    {label, opts} = Keyword.pop!(opts, :from)
    options = option_labels |> List.wrap() |> Enum.map(&%{label: &1})
    fun = &Frame.select_option(session.frame_id, &1, options, &2)
    input(session, input_selector, label, opts, fun)
  end

  def check(session, input_selector, label, opts) do
    fun = &Frame.check(session.frame_id, &1, &2)
    input(session, input_selector, label, opts, fun)
  end

  def uncheck(session, input_selector, label, opts) do
    fun = &Frame.uncheck(session.frame_id, &1, &2)
    input(session, input_selector, label, opts, fun)
  end

  def choose(session, input_selector, label, opts) do
    fun = &Frame.check(session.frame_id, &1, &2)
    input(session, input_selector, label, opts, fun)
  end

  def upload(session, input_selector, label, paths, opts) do
    paths = paths |> List.wrap() |> Enum.map(&Path.expand/1)
    fun = &Frame.set_input_files(session.frame_id, &1, paths, &2)
    input(session, input_selector, label, opts, fun)
  end

  defp input(session, input_selector, label, opts, fun) do
    selector =
      session
      |> maybe_within()
      |> Selector.concat(Selector.css_or_locator(input_selector))
      |> Selector.and(Selector.label(label, opts))

    selector
    |> fun.(%{timeout: timeout(opts)})
    |> handle_response(fn -> Query.find_by_label!(render_html(session), input_selector, label, opts) end)

    %{session | last_input_selector: selector}
  end

  defp maybe_within(session) do
    case session.within do
      :none -> "*"
      selector -> "css=#{selector}"
    end
  end

  defp handle_response(result, error_fun) do
    case result do
      {:error, %{name: "TimeoutError"}} ->
        error_fun.()
        raise ExUnit.AssertionError, message: "Could not find element."

      {:error, %{name: "Error", message: "Error: strict mode violation" <> _}} ->
        error_fun.()
        raise ExUnit.AssertionError, message: "Found more than one element."

      {:error, %{name: "Error", message: "Clicking the checkbox did not change its state"}} ->
        :ok

      {:ok, result} ->
        result
    end
  end

  def submit(session) do
    Frame.press(session.frame_id, session.last_input_selector, "Enter")
    session
  end

  def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
    {:ok, html} = Frame.content(session.frame_id)

    fixed_html =
      html
      |> Floki.parse_document!()
      |> Floki.traverse_and_update(&OpenBrowser.prefix_static_paths(&1, @endpoint))
      |> Floki.raw_html()

    path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])
    File.write!(path, fixed_html)
    open_fun.(path)

    session
  end

  def unwrap(session, fun) do
    fun.(session.frame_id)
    session
  end

  def current_path(session) do
    resp =
      session.frame_id
      |> Connection.responses()
      |> Enum.find(&match?(%{method: "navigated", params: %{url: _}}, &1))

    if resp == nil, do: raise(ArgumentError, "Could not find current path.")

    uri = URI.parse(resp.params.url)
    [uri.path, uri.query] |> Enum.reject(&is_nil/1) |> Enum.join("?")
  end

  defp timeout(opts \\ []) do
    default = Application.get_env(:phoenix_test, :timeout, @default_timeout)
    Keyword.get(opts, :timeout, default)
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Playwright do
  alias PhoenixTest.Assertions
  alias PhoenixTest.Playwright

  defdelegate visit(session, path), to: Playwright
  defdelegate render_page_title(session), to: Playwright
  defdelegate render_html(session), to: Playwright
  defdelegate click_link(session, selector, text), to: Playwright
  defdelegate click_button(session, selector, text), to: Playwright
  defdelegate within(session, selector, fun), to: Playwright
  defdelegate fill_in(session, input_selector, label, opts), to: Playwright
  defdelegate select(session, input_selector, option, opts), to: Playwright
  defdelegate check(session, input_selector, label, opts), to: Playwright
  defdelegate uncheck(session, input_selector, label, opts), to: Playwright
  defdelegate choose(session, input_selector, label, opts), to: Playwright
  defdelegate upload(session, input_selector, label, path, opts), to: Playwright
  defdelegate submit(session), to: Playwright
  defdelegate open_browser(session), to: Playwright
  defdelegate open_browser(session, open_fun), to: Playwright
  defdelegate unwrap(session, fun), to: Playwright
  defdelegate current_path(session), to: Playwright

  defdelegate assert_has(session, selector), to: Playwright
  defdelegate assert_has(session, selector, opts), to: Playwright
  defdelegate refute_has(session, selector), to: Playwright
  defdelegate refute_has(session, selector, opts), to: Playwright

  def assert_path(session, path), do: Playwright.retry(fn -> Assertions.assert_path(session, path) end)
  def assert_path(session, path, opts), do: Playwright.retry(fn -> Assertions.assert_path(session, path, opts) end)
  def refute_path(session, path), do: Playwright.retry(fn -> Assertions.refute_path(session, path) end)
  def refute_path(session, path, opts), do: Playwright.retry(fn -> Assertions.refute_path(session, path, opts) end)
end
