defmodule PhoenixTest.WallabyTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    conn = with_js_driver(Phoenix.ConnTest.build_conn())
    %{conn: conn}
  end

  describe "unwrap" do
    test "provides an escape hatch that gives access to the underlying view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> unwrap(fn session ->
        session
        |> Wallaby.Browser.clear(Wallaby.Query.text_field("Notes"))
        |> Wallaby.Browser.fill_in(Wallaby.Query.text_field("Notes"), with: "Wow")
        |> Wallaby.Browser.click(Wallaby.Query.button("Save Full Form"))
      end)
      |> assert_has("#form-data", text: "notes: Wow")
    end
  end

  describe "assert_has/3 title" do
    test "asserts on page title", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    test "asserts on updated page title", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Change page title")
      |> assert_has("title", text: "Title changed!")
    end

    test "refutes missing page title", %{conn: conn} do
      conn
      |> visit("/live/index_no_layout")
      |> refute_has("title")
    end
  end

  describe "assert_path" do
    test "it asserts on visit", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_path("/live/index")
    end

    test "it asserts on visit with query string", %{conn: conn} do
      conn
      |> visit("/live/index?foo=bar")
      |> assert_path("/live/index", query_params: %{foo: "bar"})
    end

    test "it asserts on href navigation", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_path("/page/index", query_params: %{details: true, foo: "bar"})
    end

    test "it asserts on live navigation", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_path("/live/page_2", query_params: %{details: true, foo: "bar"})
    end
  end
end
