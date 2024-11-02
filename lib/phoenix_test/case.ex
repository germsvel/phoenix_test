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
      %{playwright: p} when p != false ->
        [conn: Case.Playwright.start_session(context)]

      _ ->
        [conn: Phoenix.ConnTest.build_conn()]
    end
  end

  defmodule Playwright do
    @moduledoc false
    import PhoenixTest.Playwright.Connection

    @includes_ecto Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) &&
                     Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox)

    def launch_browser(opts) do
      opts = Map.new(opts)
      ensure_started(opts)
      browser_id = launch_browser(opts.browser, opts)
      on_exit(fn -> sync_post(guid: browser_id, method: "close") end)
      browser_id
    end

    def start_session(%{browser_id: browser_id} = context) do
      user_agent = checkout_ecto_repos(context[:async])
      params = if user_agent, do: %{userAgent: user_agent}, else: %{}
      context_id = sync_post(guid: browser_id, method: "newContext", params: params).result.context.guid
      on_exit(fn -> post(guid: context_id, method: "close") end)

      page_id = sync_post(guid: context_id, method: "newPage").result.page.guid
      [%{params: %{guid: "frame" <> _ = frame_id}}] = responses(page_id)

      PhoenixTest.Playwright.build(frame_id)
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
