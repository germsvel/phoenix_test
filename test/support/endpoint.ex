defmodule PhoenixTest.Endpoint do
  use Plug.Test
  # import Phoenix.ConnTest

  @fixtures "test/support/fixtures/"

  def init(opts), do: opts

  def call(conn, _opts) do
    handle_request(conn, conn.method, conn.request_path)
  end

  defp handle_request(conn, "GET", path) do
    filepath = Path.join(@fixtures, path <> ".html")
    html = File.read!(filepath)

    conn
    |> put_resp_content_type("text/html")
    |> resp(200, html)
  end
end
