defmodule PhoenixTestTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given path", %{conn: conn} do
      conn
      |> visit("/index")
      |> assert_has("h1", "Main page")
    end
  end

  describe "click_link/2" do
    test "navigates to path", %{conn: conn} do
      conn
      |> visit("/index")
      |> click_link("Page 2")
      |> assert_has("h1", "Page 2")
    end
  end
end
