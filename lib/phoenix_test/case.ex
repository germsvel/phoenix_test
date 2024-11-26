defmodule PhoenixTest.Case do
  @moduledoc """
  ExUnit case module to assist with browser based tests.
  See `PhoenixTest.Playwright` for more information.
  """

  use ExUnit.CaseTemplate

  alias PhoenixTest.Case

  using opts do
    quote do
      import PhoenixTest

      setup do
        [phoenix_test: unquote(opts)]
      end
    end
  end

  @playwright_opts [
    browser: :chromium,
    headless: true,
    slowMo: 0
  ]

  setup_all context do
    trace = Application.fetch_env!(:phoenix_test, :playwright)[:trace]

    case context do
      %{playwright: true} ->
        [browser_id: Case.Playwright.launch_browser(@playwright_opts), trace: trace]

      %{playwright: opts} when is_list(opts) ->
        opts = Keyword.merge(@playwright_opts, opts)
        [browser_id: Case.Playwright.launch_browser(opts), trace: trace]

      _ ->
        :ok
    end
  end

  setup context do
    case context do
      %{playwright: p} when p != false ->
        [conn: Case.Playwright.new_session(context)]

      _ ->
        [conn: Phoenix.ConnTest.build_conn()]
    end
  end

  defmodule Playwright do
    @moduledoc false
    import PhoenixTest.Playwright.Connection

    alias PhoenixTest.Playwright.Browser
    alias PhoenixTest.Playwright.BrowserContext

    @includes_ecto Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) &&
                     Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox)

    def launch_browser(opts) do
      ensure_started()
      browser = Keyword.fetch!(opts, :browser)
      browser_id = launch_browser(browser, opts)
      on_exit(fn -> post(guid: browser_id, method: "close") end)
      browser_id
    end

    def new_session(%{browser_id: browser_id} = context) do
      context_id = Browser.new_context(browser_id)
      subscribe(context_id)

      page_id = BrowserContext.new_page(context_id)
      post(%{method: :updateSubscription, guid: page_id, params: %{event: "console", enabled: true}})
      frame_id = initializer(page_id).mainFrame.guid
      on_exit(fn -> post(guid: context_id, method: "close") end)

      if context[:trace] do
        BrowserContext.start_tracing(context_id)

        dir = :phoenix_test |> Application.fetch_env!(:playwright) |> Keyword.fetch!(:trace_dir)
        File.mkdir_p!(dir)

        "Elixir." <> case = to_string(context.case)
        session_id = System.unique_integer([:positive, :monotonic])
        file = String.replace("#{case}.#{context.test}_#{session_id}.zip", ~r/[^a-zA-Z0-9 \.]/, "_")
        path = Path.join(dir, file)

        on_exit(fn -> BrowserContext.stop_tracing(context_id, path) end)
      end

      PhoenixTest.Playwright.build(page_id, frame_id)
    end

    if @includes_ecto do
      def checkout_ecto_repos(async?) do
        otp_app = Application.fetch_env!(:phoenix_test, :otp_app)
        repos = Application.fetch_env!(otp_app, :ecto_repos)

        repos
        |> Enum.map(&checkout_ecto_repo(&1, async?))
        |> Phoenix.Ecto.SQL.Sandbox.metadata_for(self())
        |> Phoenix.Ecto.SQL.Sandbox.encode_metadata()
      end

      defp checkout_ecto_repo(repo, async?) do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)
        unless async?, do: Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

        repo
      end
    else
      def checkout_ecto_repos(_) do
        nil
      end
    end
  end
end
