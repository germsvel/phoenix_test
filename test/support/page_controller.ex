defmodule PhoenixTest.PageController do
  use Phoenix.Controller

  plug(:put_layout, false)

  def show(conn, %{"page" => page}) do
    conn
    |> render(page <> ".html")
  end

  def create(conn, params) do
    conn
    |> assign(:params, params)
    |> render("record_created.html")
  end

  def update(conn, _) do
    conn
    |> render("record_updated.html")
  end

  def delete(conn, _) do
    conn
    |> render("record_deleted.html")
  end
end
