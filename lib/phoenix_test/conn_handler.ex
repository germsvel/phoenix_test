defmodule PhoenixTest.ConnHandler do
  @moduledoc false
  import Phoenix.ConnTest

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  def visit(conn, path) do
    case get(conn, path) do
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

  def recycle_all_headers(conn) do
    recycle(conn, all_headers(conn))
  end

  defp all_headers(conn) do
    Enum.map(conn.req_headers, &elem(&1, 0))
  end
end
