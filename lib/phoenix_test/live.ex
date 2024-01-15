defmodule PhoenixTest.Live do
  defstruct [:view, :conn]

  def visit(view, conn) do
    %__MODULE__{view: view, conn: conn}
  end
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Live do
  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  def click_link(session, text) do
    result =
      session.view
      |> element("a", text)
      |> render_click()
      |> maybe_redirect(session)

    case result do
      {:ok, view, _} ->
        %{session | view: view}

      {:static_view, conn, path} ->
        PhoenixTest.visit(conn, path)
    end
  end

  def render_html(%{view: view}) do
    render(view)
  end

  defp maybe_redirect({:error, {:redirect, %{to: path}}}, session) do
    {:static_view, session.conn, path}
  end

  defp maybe_redirect({:error, {:live_redirect, _}} = result, session) do
    result
    |> follow_redirect(session.conn)
  end

  defp maybe_redirect(html, session) when is_binary(html) do
    {:ok, session.view, html}
  end
end
