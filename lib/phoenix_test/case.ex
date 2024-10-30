defmodule PhoenixTest.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias PhoenixTest.Case

  @playwright_opts [
    browser: :chromium,
    headless: true,
    slowMo: 0
  ]

  setup_all context do
    case context do
      %{playwright: true} ->
        [browser_id: Case.Playwright.launch_browser(@playwright_opts)]

      %{playwright: opts} when is_list(opts) ->
        opts = Keyword.merge(@playwright_opts, opts)
        [browser_id: Case.Playwright.launch_browser(opts)]

      _ ->
        :ok
    end
  end

  setup context do
    case context do
      %{playwright: p, browser_id: browser_id} when p != false -> [conn: Case.Playwright.session(browser_id)]
      _ -> [conn: Phoenix.ConnTest.build_conn()]
    end
  end

  defmodule Playwright do
    @moduledoc false
    import PhoenixTest.Playwright.Connection

    def launch_browser(opts) do
      opts = Map.new(opts)
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
