defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Assertions

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "assert_has/3" do
    test "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      conn |> assert_has("h1", "Main page")
      conn |> assert_has("#title", "Main page")
      conn |> assert_has(".title", "Main page")
      conn |> assert_has("[data-role='title']", "Main page")
    end

    test "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn =
        conn
        |> visit("/live/index")

      conn |> assert_has("h1", "LiveView main page")
      conn |> assert_has("#title", "LiveView main page")
      conn |> assert_has(".title", "LiveView main page")
      conn |> assert_has("[data-role='title']", "LiveView main page")
    end

    test "succeeds if more than one element matces selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", "Aragorn")
    end

    test "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", "Has extra space")
    end

    test "raises an error if the element cannot be found", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      assert_raise RuntimeError, ~r/Could not find element with selector "#nonexistent-id"/, fn ->
        conn |> assert_has("#nonexistent-id", "Main page")
      end
    end
  end

  describe "refute_has/3" do
    test "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      conn |> refute_has("h1", "Not main page")
      conn |> refute_has("h2", "Main page")
      conn |> refute_has("#incorrect-id", "Main page")
      conn |> refute_has("#title", "Not main page")
    end

    test "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn =
        conn
        |> visit("/live/index")

      conn |> refute_has("h1", "Not main page")
      conn |> refute_has("h2", "Main page")
      conn |> refute_has("#incorrect-id", "Main page")
      conn |> refute_has("#title", "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      assert_raise RuntimeError,
                   ~s(Found element with selector "#title" and text "Main page" when should not be present),
                   fn ->
                     conn |> refute_has("#title", "Main page")
                   end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      assert_raise RuntimeError,
                   ~s(Found element with selector ".multiple_links" and text "Multiple links" when should not be present),
                   fn ->
                     conn |> refute_has(".multiple_links", "Multiple links")
                   end
    end
  end
end
