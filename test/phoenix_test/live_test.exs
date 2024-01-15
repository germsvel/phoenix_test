defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Driver
  import PhoenixTest.Assertions

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", "LiveView main page")
    end
  end

  describe "click_link/2" do
    test "follows link navigate path", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_has("h1", "LiveView page 2")
    end

    test "handles patches to current view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Patch link")
      |> assert_has("h2", "LiveView main page details")
    end
  end
end
