defmodule PhoenixTest.Static do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  alias PhoenixTest.Html

  defstruct [:conn]

  def visit(conn, path) do
    %__MODULE__{conn: get(conn, path)}
  end

  defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
    def click_link(session, text) do
      path =
        session
        |> render_html()
        |> Html.parse()
        |> Html.find("a", text)
        |> Html.attribute("href")

      PhoenixTest.visit(session.conn, path)
    end

    def render_html(%{conn: conn}) do
      conn
      |> html_response(200)
    end
  end
end
