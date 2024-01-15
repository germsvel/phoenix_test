defmodule PhoenixTest.PageController do
  use Phoenix.Controller

  plug(:put_layout, false)

  def show(conn, %{"page" => page}) do
    conn
    |> render(page <> ".html")
  end

  def update(conn, _) do
    conn
    |> render("updated_page.html")
  end
end
