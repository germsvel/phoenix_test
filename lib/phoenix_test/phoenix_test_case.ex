defmodule PhoenixTest.Case do
  @moduledoc false

  defmacro __using__(options \\ []) do
    quote do
      import PhoenixTest

      setup_all do
        [conn: Phoenix.ConnTest.build_conn()]
      end

      if Code.ensure_loaded?(Playwright.Page) and unquote(options[:playwright]) do
        setup_all(context) do
          opts = Map.new(unquote(options))
          PhoenixTest.Case.setup_all_playwright(opts)
        end

        setup(context) do
          PhoenixTest.Case.setup_playwright(context)
        end
      end
    end
  end

  if Code.ensure_loaded?(Playwright.Page) do
    def setup_all_playwright(options) do
      client = options.playwright
      launch_options = Map.merge(Playwright.SDK.Config.launch_options(), options)
      runner_options = Map.merge(Playwright.SDK.Config.playwright_test(), options)
      Application.put_env(:playwright, LaunchOptions, launch_options)
      {:ok, _} = Application.ensure_all_started(:playwright)
      browser = setup_browser(client, runner_options, launch_options)

      [browser: browser]
    end

    def setup_playwright(%{playwright: _} = context) do
      page = Playwright.Browser.new_page(context.browser)
      ExUnit.Callbacks.on_exit(fn -> Playwright.Page.close(page) end)

      [conn: page]
    end

    def setup_playwright(_context) do
      [conn: Phoenix.ConnTest.build_conn()]
    end

    defp setup_browser(true = _client, runner_options, launch_options) do
      setup_browser(:chromium, runner_options, launch_options)
    end

    defp setup_browser(client, runner_options, launch_options) do
      case runner_options.transport do
        :driver ->
          {_pid, browser} = Playwright.BrowserType.launch(client, launch_options)
          ExUnit.Callbacks.on_exit(fn -> Playwright.Browser.close(browser) end)
          browser

        :websocket ->
          options = Playwright.SDK.Config.connect_options()
          {_pid, browser} = Playwright.BrowserType.connect(options.ws_endpoint)
          browser
      end
    end
  end
end
