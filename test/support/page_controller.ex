defmodule PhoenixTest.PageController do
  use Phoenix.Controller

  plug(:put_layout, false)

  def show(conn, %{"page" => page}) do
    conn
    |> render(page <> ".html")
  end
end
