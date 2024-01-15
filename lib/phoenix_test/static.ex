defmodule PhoenixTest.Static do
  defstruct [:conn]

  def build(conn) do
    %__MODULE__{conn: conn}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Static do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  alias PhoenixTest.Html

  def click_link(session, text) do
    path =
      session
      |> render_html()
      |> Html.parse()
      |> Html.find("a", text)
      |> Html.attribute("href")

    PhoenixTest.visit(session.conn, path)
  end

  def click_button(session, text) do
    action =
      session
      |> render_html()
      |> Html.parse()
      |> Html.find("form", text)
      |> Html.attribute("action")

    conn = put(session.conn, action)

    %{session | conn: conn}
  end

  def render_html(%{conn: conn}) do
    conn
    |> html_response(200)
  end
end
