defmodule PhoenixTest.ConnHandlerTest do
  use ExUnit.Case, async: true

  import PhoenixTest, only: [assert_has: 3]

  alias PhoenixTest.ConnHandler

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to LiveView pages", %{conn: conn} do
      conn
      |> ConnHandler.visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "navigates to static pages", %{conn: conn} do
      conn
      |> ConnHandler.visit("/page/index")
      |> assert_has("h1", text: "Main page")
    end

    test "follows LiveView mount redirects", %{conn: conn} do
      conn
      |> ConnHandler.visit("/live/redirect_on_mount/redirect")
      |> assert_has("h1", text: "LiveView main page")
      |> assert_has("#flash-group", text: "Redirected!")
    end

    test "follows push redirects (push navigate)", %{conn: conn} do
      conn
      |> ConnHandler.visit("/live/redirect_on_mount/push_navigate")
      |> assert_has("h1", text: "LiveView main page")
      |> assert_has("#flash-group", text: "Navigated!")
    end

    test "follows static redirects", %{conn: conn} do
      conn
      |> ConnHandler.visit("/page/redirect_to_static")
      |> assert_has("h1", text: "Main page")
      |> assert_has("#flash-group", text: "Redirected!")
    end

    test "preserves headers across redirects", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> ConnHandler.visit("/live/redirect_on_mount/redirect")
      |> assert_has("h1", text: "LiveView main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test "raises error if route doesn't exist", %{conn: conn} do
      assert_raise ArgumentError, ~r/path doesn't exist/, fn ->
        ConnHandler.visit(conn, "/non_route")
      end
    end
  end

  describe "visit/1" do
    test "raises error if page hasn't been visited yet", %{conn: conn} do
      assert_raise ArgumentError, ~r/must visit a page/, fn ->
        ConnHandler.visit(conn)
      end
    end
  end
end
