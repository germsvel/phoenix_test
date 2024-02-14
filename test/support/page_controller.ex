defmodule PhoenixTest.PageController do
  use Phoenix.Controller

  plug(:put_layout, {PhoenixTest.PageView, :layout})

  def show(conn, %{"page" => "index_no_layout"}) do
    conn
    |> put_layout({PhoenixTest.PageView, :empty_layout})
    |> render("index.html")
  end

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

  def redirect_to_liveview(conn, _) do
    conn
    |> redirect(to: "/live/index")
  end

  def redirect_to_static(conn, _) do
    conn
    |> redirect(to: "/page/index")
  end
end
