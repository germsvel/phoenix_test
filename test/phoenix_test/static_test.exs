defmodule PhoenixTest.StaticTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Driver
  import PhoenixTest.Assertions

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given static page", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", "Main page")
    end
  end

  describe "click_link/2" do
    test "follows link's path", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Page 2")
      |> assert_has("h1", "Page 2")
    end

    test "follows first link when there are multiple links with same text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Multiple links")
      |> assert_has("h1", "Page 3")
    end
  end

  describe "click_button/2" do
    test "handles a button clicks when button is a form", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Mark as active")
      |> assert_has("h1", "Marked active!")
    end
  end
end
