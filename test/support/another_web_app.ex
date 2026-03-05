# A minimal second Phoenix application used to demonstrate and test that
# PhoenixTest supports multiple endpoints within the same test suite.
#
# Tests can target this endpoint by calling:
#
#   Phoenix.ConnTest.build_conn() |> PhoenixTest.put_endpoint(PhoenixTest.AnotherWebApp.Endpoint)
#
# This is distinct from PhoenixTest.WebApp, allowing tests to assert that
# `put_endpoint/2` correctly routes each conn to its respective endpoint.

defmodule PhoenixTest.AnotherWebApp.PageLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>AnotherWebApp page</h1>
    """
  end
end

defmodule PhoenixTest.AnotherWebApp.Router do
  @moduledoc false
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixTest.WebApp.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PhoenixTest.AnotherWebApp do
    pipe_through [:browser]

    live_session :default, layout: {PhoenixTest.WebApp.LayoutView, :app} do
      live "/page", PageLive
    end
  end
end

defmodule PhoenixTest.AnotherWebApp.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :phoenix_test

  @session_options [
    store: :cookie,
    key: "_another_phoenix_key",
    signing_salt: "anotheRsalt",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.RequestId
  plug Plug.Session, @session_options
  plug PhoenixTest.AnotherWebApp.Router
end
