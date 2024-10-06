if Code.ensure_loaded?(Playwright.Page) do
  defmodule PhoenixTest.Playwright do
    @moduledoc false

    alias ExUnit.AssertionError
    alias PhoenixTest.Assertions
    alias PhoenixTest.OpenBrowser
    alias PhoenixTest.Playwright.Locator, as: L
    alias Playwright.Locator
    alias Playwright.Page
    alias Playwright.SDK.Channel

    defstruct [:page, within: :none]

    @endpoint Application.compile_env(:phoenix_test, :endpoint)
    @default_timeout :timer.seconds(1)

    def build(page, path) do
      base_url = Application.fetch_env!(:phoenix_test, :base_url)
      Page.goto(page, base_url <> path)
      %__MODULE__{page: page}
    end

    def assert_has(session, selector, opts \\ []) do
      unless found?(session, selector, opts) do
        raise(AssertionError, Assertions.assert_not_found_error_msg(selector, opts, []))
      end

      session
    end

    def refute_has(session, selector, opts \\ []) do
      if found?(session, selector, opts, is_not: true) do
        raise(AssertionError, Assertions.refute_found_error_msg(selector, opts, []))
      end

      session
    end

    defp found?(session, selector, opts, query_attrs \\ []) do
      # TODO
      if opts[:count], do: raise("count not implemented")

      locator =
        session
        |> maybe_within()
        |> L.concat(L.css(selector))
        |> L.concat(L.text(opts[:text], opts))
        |> L.concat(L.at(opts[:at]))

      query =
        Enum.into(query_attrs, %{
          expression: "to.be.visible",
          is_not: false,
          selector: locator.selector,
          timeout: timeout(opts)
        })

      Channel.post(session.page.session, {:guid, locator.frame.guid}, :expect, query)
    end

    def render_page_title(session) do
      Page.title(session.page)
    end

    def render_html(session) do
      session
      |> maybe_within()
      |> Locator.inner_html()
    end

    def click_link(session, selector, text) do
      session
      |> maybe_within()
      |> L.concat(L.css(selector))
      |> L.concat(L.text(text, exact: false))
      |> Locator.click(%{timeout: timeout()})
      |> handle_result(selector)

      session
    end

    def click_button(session, selector, text) do
      session
      |> maybe_within()
      |> L.concat(L.css(selector))
      |> L.concat(L.text(text, exact: false))
      |> Locator.click(%{timeout: timeout()})
      |> handle_result(selector)

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
      fun = &Locator.fill(&1, to_string(value), &2)
      input(session, input_selector, label, opts, fun)
    end

    def select(session, input_selector, option, opts) do
      {label, opts} = Keyword.pop!(opts, :from)
      fun = &Locator.select_option(&1, %{label: option}, &2)
      input(session, input_selector, label, opts, fun)
    end

    def check(session, input_selector, label, opts) do
      fun = &Locator.check/2
      input(session, input_selector, label, opts, fun)
    end

    def uncheck(session, input_selector, label, opts) do
      fun = &Locator.uncheck/2
      input(session, input_selector, label, opts, fun)
    end

    def choose(session, input_selector, label, opts) do
      fun = &Locator.check/2
      input(session, input_selector, label, opts, fun)
    end

    def upload(session, input_selector, label, paths, opts) do
      fun = &Locator.set_input_files(&1, List.wrap(paths), &2)
      input(session, input_selector, label, opts, fun)
    end

    defp input(session, input_selector, label, opts, fun) do
      session
      |> maybe_within()
      |> L.concat(L.css(input_selector))
      |> L.and(L.label(label, opts))
      |> fun.(%{timeout: timeout(opts)})
      |> handle_result(input_selector, label)

      session
    end

    defp maybe_within(session) do
      case session.within do
        :none -> Locator.new(session.page, "*")
        selector -> Page.locator(session.page, "css=#{selector}")
      end
    end

    defp handle_result(result, selector, label \\ nil) do
      case result do
        list when is_list(list) ->
          {:ok, list}

        :ok ->
          result

        {:ok, _} ->
          result

        {:error, %{type: "Error", message: "Error: strict mode violation" <> _}} ->
          raise(ArgumentError, "Found more than one element with selector #{inspect(selector)}")

        {:error, %{type: "TimeoutError"}} ->
          msg =
            case label do
              nil -> "Could not find element with selector #{inspect(selector)}."
              _ -> "Could not find element with label #{inspect(label)}."
            end

          raise(ArgumentError, msg)

        {:error, %{type: "Error", message: "Clicking the checkbox did not change its state"}} ->
          :ok
      end
    end

    def submit(session) do
      Page.Keyboard.down(session.page, "Enter")
      session
    end

    def open_browser(session, open_fun \\ &OpenBrowser.open_with_system_cmd/1) do
      html =
        session.page
        |> Page.content()
        |> Floki.parse_document!()
        |> Floki.traverse_and_update(&OpenBrowser.prefix_static_paths(&1, @endpoint))
        |> Floki.raw_html()

      path = Path.join([System.tmp_dir!(), "phx-test#{System.unique_integer([:monotonic])}.html"])
      File.write!(path, html)
      open_fun.(path)

      session
    end

    def unwrap(session, fun) do
      fun.(session.page)
      session
    end

    def current_path(session) do
      url = Page.url(session.page)
      uri = URI.parse(url)
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
    defdelegate assert_path(session, path), to: Assertions
    defdelegate assert_path(session, path, opts), to: Assertions
    defdelegate refute_path(session, path), to: Assertions
    defdelegate refute_path(session, path, opts), to: Assertions
  end
end
