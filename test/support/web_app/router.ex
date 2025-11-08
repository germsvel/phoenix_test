defmodule PhoenixTest.WebApp.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :setup_session do
    plug(Plug.Session,
      store: :cookie,
      key: "_phoenix_test_key",
      signing_salt: "/VADsdfSfdMnp5"
    )

    plug(:fetch_session)
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixTest.WebApp.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PhoenixTest.WebApp do
    pipe_through([:browser])

    post "/page/create_record", PageController, :create
    put "/page/update_record", PageController, :update
    delete "/page/delete_record", PageController, :delete
    get "/page/unauthorized", PageController, :unauthorized
    get "/page/redirect_to_static", PageController, :redirect_to_static
    post "/page/redirect_to_liveview", PageController, :redirect_to_liveview
    post "/page/redirect_to_static", PageController, :redirect_to_static
    get "/page/:page", PageController, :show

    live_session :live_pages, layout: {PhoenixTest.WebApp.LayoutView, :app} do
      live "/live/index", IndexLive
      live "/live/index/alias", IndexLive
      live "/live/page_2", Page2Live
      live "/live/async_page", AsyncPageLive
      live "/live/async_page_2", AsyncPage2Live
      live "/live/dynamic_form", DynamicFormLive
      live "/live/simple_ordinal_inputs", SimpleOrdinalInputsLive
      live "/live/nested", NestedLive
    end

    scope "/auth" do
      pipe_through([:proxy_header_auth])

      live_session :auth, layout: {PhoenixTest.WebApp.LayoutView, :app} do
        live "/live/index", IndexLive
        live "/live/page_2", Page2Live
      end
    end

    live "/live/redirect_on_mount/:redirect_type", RedirectLive
  end

  def proxy_header_auth(conn, _opts) do
    case get_req_header(conn, "x-auth-header") do
      [value] -> put_session(conn, :auth_header, value)
      _ -> conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end
end
