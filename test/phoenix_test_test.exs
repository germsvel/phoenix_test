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
    test "follows link's path", %{conn: conn} do
      conn
      |> visit("/index")
      |> click_link("Page 2")
      |> assert_has("h1", "Page 2")
    end

    test "follows first link when there are multiple links with same text", %{conn: conn} do
      conn
      |> visit("/index")
      |> click_link("Multiple links")
      |> assert_has("h1", "Page 3")
    end
  end

  describe "assert_has/3" do
    test "returns true if a single element is found with CSS selector and text", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      conn |> assert_has("h1", "Main page")
      conn |> assert_has("#title", "Main page")
      conn |> assert_has(".title", "Main page")
      conn |> assert_has("[data-role='title']", "Main page")
    end

    test "raises an error if the element cannot be found", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      assert_raise RuntimeError, ~s(unable to find element with selector "#nonexistent-id"), fn ->
        conn |> assert_has("#nonexistent-id", "Main page")
      end
    end

    test "raises an error if more than one element is found", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      assert_raise RuntimeError,
                   ~s(found more than one element with selector ".multiple_links"),
                   fn ->
                     conn |> assert_has(".multiple_links", "Multiple links")
                   end
    end
  end

  describe "refute_has/3" do
    test "succeeds if no element is found with CSS selector and text", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      conn |> refute_has("h1", "Not main page")
      conn |> refute_has("h2", "Main page")
      conn |> refute_has("#incorrect-id", "Main page")
      conn |> refute_has("#title", "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      assert_raise RuntimeError,
                   ~s(Found element with selector "#title" and text "Main page" when should not be present),
                   fn ->
                     conn |> refute_has("#title", "Main page")
                   end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn =
        conn
        |> visit("/index")

      assert_raise RuntimeError,
                   ~s(Found element with selector ".multiple_links" and text "Multiple links" when should not be present),
                   fn ->
                     conn |> refute_has(".multiple_links", "Multiple links")
                   end
    end
  end
end
