defmodule PhoenixTest.Case do
  @moduledoc """
  ExUnit case module to assist with browser based tests.
  See `PhoenixTest.Playwright` for more information.

  ## Configuration
  Set browser launch options via a `@moduletag` or `setup_all`:application

  ```ex
  @moduletag playwright: [browser: :chromium, headless: false, slowMo: 1000]
  ```

  You can opt out of Playwright for selected tests via tags:

  ```ex
  describe "part of feature without javascript"
    @describetag playwright: false

    test "regular dead or live view without javascript" do
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

    def launch_browser(opts) do
      opts = Map.new(opts)
      ensure_started(opts)
      browser_id = launch_browser(opts.browser, opts)
      on_exit(fn -> sync_post(guid: browser_id, method: "close") end)
      browser_id
    end

    def start_session(%{browser_id: browser_id} = context) do
      params = browser_context_params(context)
      context_id = sync_post(guid: browser_id, method: "newContext", params: params).result.context.guid
      on_exit(fn -> post(guid: context_id, method: "close") end)

      page_id = sync_post(guid: context_id, method: "newPage").result.page.guid
      [%{params: %{guid: "frame" <> _ = frame_id}}] = responses(page_id)

      PhoenixTest.Playwright.build(frame_id)
    end

    if Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox) do
      defp browser_context_params(%{repo: repo} = context) do
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not context[:async])
        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(repo, pid)
        encoded = {:v1, metadata} |> :erlang.term_to_binary() |> Base.url_encode64()
        %{userAgent: "BeamMetadata (#{encoded})"}
      end
    end

    defp browser_context_params(_), do: %{}
  end
end
