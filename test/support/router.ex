defmodule PhoenixTest.Router do
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
    plug(:setup_session)
    plug(:accepts, ["html"])
    plug(:fetch_live_flash)
  end

  scope "/", PhoenixTest do
    pipe_through([:browser])

    post "/page/create_record", PageController, :create
    put "/page/update_record", PageController, :update
    delete "/page/delete_record", PageController, :delete
    get "/page/unauthorized", PageController, :unauthorized
    get "/page/redirect_to_static", PageController, :redirect_to_static
    post "/page/redirect_to_liveview", PageController, :redirect_to_liveview
    post "/page/redirect_to_static", PageController, :redirect_to_static
    get "/page/:page", PageController, :show

    live_session :live_pages, root_layout: {PhoenixTest.PageView, :layout} do
      live "/live/index", IndexLive
      live "/live/index/alias", IndexLive
      live "/live/page_2", Page2Live
    end

    scope "/auth" do
      pipe_through([:proxy_header_auth])

      live "/live/index", IndexLive
      live "/live/page_2", Page2Live
    end

    live "/live/index_no_layout", IndexLive
    live "/live/redirect_on_mount/:redirect_type", RedirectLive
  end

  def proxy_header_auth(conn, _opts) do
    case get_req_header(conn, "x-auth-header") do
      [value] -> put_session(conn, :auth_header, value)
      _ -> conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end
end
