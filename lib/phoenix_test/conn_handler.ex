defmodule PhoenixTest.ConnHandler do
  @moduledoc false
  import Phoenix.ConnTest

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  def visit(conn, path) do
    conn
    |> get(path)
    |> visit()
  end

  def visit(conn) do
    if route_exists?(conn) do
      case conn do
        %{assigns: %{live_module: _}} = conn ->
          PhoenixTest.Live.build(conn)

        %{status: 302} = conn ->
          path = redirected_to(conn)

          conn
          |> recycle_all_headers()
          |> visit(path)

        conn ->
          PhoenixTest.Static.build(conn)
      end
    else
      raise ArgumentError, message: "#{inspect(conn.request_path)} path doesn't exist"
    end
  end

  def recycle_all_headers(conn) do
    recycle(conn, all_headers(conn))
  end

  defp all_headers(conn) do
    Enum.map(conn.req_headers, &elem(&1, 0))
  end

  defp route_exists?(conn) do
    router = fetch_phoenix_router!(conn)
    method = conn.method
    host = conn.host
    path = conn.request_path

    case Phoenix.Router.route_info(router, method, path, host) do
      %{} -> true
      :error -> false
    end
  end

  defp fetch_phoenix_router!(conn) do
    case conn.private[:phoenix_router] do
      nil ->
        raise ArgumentError, message: "You must visit a page before calling `visit/1` or call `visit/2` with a path"

      router when is_atom(router) ->
        router
    end
  end
end
