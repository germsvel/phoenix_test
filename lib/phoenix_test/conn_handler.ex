defmodule PhoenixTest.ConnHandler do
  @moduledoc false
  import Phoenix.ConnTest
  alias PhoenixTest.Utils

  def visit(conn, path) do
    conn
    |> dispatch(Utils.current_endpoint(), :get, path)
    |> visit()
  end

  def visit(conn) do
    verify_when_local_path!(conn)

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
  end

  def build_current_path(conn), do: append_query_string(conn.request_path, conn.query_string)

  defp append_query_string(path, ""), do: path
  defp append_query_string(path, query), do: path <> "?" <> query

  def recycle_all_headers(conn) do
    recycle(conn, all_headers(conn))
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
    conn.host == @plug_adapters_test_conn_default_host or conn.host == endpoint_host()
  end

  defp endpoint_host do
    endpoint_at_runtime_to_avoid_warning = Application.get_env(:phoenix_test, :endpoint)
    endpoint_at_runtime_to_avoid_warning.host()
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
