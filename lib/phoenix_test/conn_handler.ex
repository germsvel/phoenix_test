defmodule PhoenixTest.ConnHandler do
  @moduledoc false
  import Phoenix.ConnTest

  alias PhoenixTest.EndpointHelpers

  def visit(conn, path) do
    conn
    |> Phoenix.ConnTest.dispatch(EndpointHelpers.endpoint_from!(conn), :get, path, nil)
    |> visit()
  end

  def visit(conn) do
    verify_when_local_path!(conn)

    case conn do
      %{assigns: %{live_module: _}} = conn ->
        PhoenixTest.Live.build(conn)

      %{status: status} = conn when status in [301, 302, 303, 307, 308] ->
        path = redirected_to(conn, status)

        conn
        |> recycle_all_headers()
        |> visit(path)

      conn ->
        PhoenixTest.Static.build(conn)
    end
  end

  def build_current_path(conn), do: append_query_string(conn.request_path, conn.query_string)

  defp append_query_string(path, ""), do: path
  defp append_query_string(path, query), do: path <> "?" <> query

  def recycle_all_headers(conn) do
    conn
    |> recycle(all_headers(conn))
    |> EndpointHelpers.copy_endpoint(conn)
  end

  defp all_headers(conn) do
    Enum.map(conn.req_headers, &elem(&1, 0))
  end

  defp verify_when_local_path!(conn) do
    if local_path?(conn) && !route_exists?(conn) do
      raise ArgumentError, message: "#{inspect(conn.request_path)} path doesn't exist"
    end
  end

  @plug_adapters_test_conn_default_host "www.example.com"
  defp local_path?(conn) do
    conn.host == @plug_adapters_test_conn_default_host or conn.host == EndpointHelpers.endpoint_from!(conn).host()
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
