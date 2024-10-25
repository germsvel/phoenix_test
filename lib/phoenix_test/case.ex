defmodule PhoenixTest.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias PhoenixTest.Case

  @playwright_opts %{
    browser: :chromium,
    headless: true,
    slowMo: 0
  }

  setup_all context do
    case context do
      %{playwright: opts} ->
        opts = Map.merge(@playwright_opts, if(opts == true, do: %{}, else: Map.new(opts)))
        browser_id = Case.Playwright.launch_browser(opts)
        [playwright: true, browser_id: browser_id]

      _ ->
        :ok
    end
  end

  setup context do
    case context do
      %{playwright: false} -> [conn: Phoenix.ConnTest.build_conn()]
      %{browser_id: browser_id} -> [conn: Case.Playwright.session(browser_id)]
    end
  end

  defmodule Playwright do
    @moduledoc false
    import PhoenixTest.Playwright.Connection

    def launch_browser(opts) do
      ensure_started(opts)
      browser_id = launch_browser(opts.browser, opts)
      on_exit(fn -> sync_post(guid: browser_id, method: "close") end)
      browser_id
    end

    def session(browser_id) do
      context_id = sync_post(guid: browser_id, method: "newContext").result.context.guid
      page_id = sync_post(guid: context_id, method: "newPage").result.page.guid
      [%{params: %{guid: "frame" <> _ = frame_id}}] = responses(page_id)
      on_exit(fn -> post(guid: context_id, method: "close") end)

      PhoenixTest.Playwright.build(frame_id)
    end
  end
end
