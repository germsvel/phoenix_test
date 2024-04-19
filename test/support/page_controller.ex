defmodule PhoenixTest.PageController do
  use Phoenix.Controller

  plug(:put_layout, {PhoenixTest.PageView, :layout})

  def show(conn, %{"page" => "index_no_layout"}) do
    conn
    |> put_layout({PhoenixTest.PageView, :empty_layout})
    |> render("index.html")
  end

  def show(conn, %{"redirect_to" => path}) do
    redirect(conn, to: path)
  end

  def show(conn, %{"page" => page}) do
    render(conn, page <> ".html")
  end

  def create(conn, params) do
    conn
    |> assign(:params, params)
    |> render("record_created.html")
  end

  def update(conn, params) do
    conn
    |> assign(:params, params)
    |> render("record_updated.html")
  end

  def delete(conn, _) do
    render(conn, "record_deleted.html")
  end

  def redirect_to_liveview(conn, _) do
    redirect(conn, to: "/live/index")
  end

  def redirect_to_static(conn, _) do
    redirect(conn, to: "/page/index")
  end

  def unauthorized(conn, _) do
    conn
    |> put_status(:unauthorized)
    |> render("unauthorized.html")
  end
end
