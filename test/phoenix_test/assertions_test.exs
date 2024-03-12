defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers

  alias ExUnit.AssertionError

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "assert_has/2" do
    test "succeeds if single element is found with CSS selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("[data-role='title']")
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#nonexistent-id")
      end
    end

    test "succeeds if element searched is title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title")
    end

    test "succeeds if element searched is title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title")
    end
  end

  describe "assert_has/3" do
    test "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", "Main page")
      |> assert_has("#title", "Main page")
      |> assert_has(".title", "Main page")
      |> assert_has("[data-role='title']", "Main page")
    end

    test "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", "LiveView main page")
      |> assert_has("#title", "LiveView main page")
      |> assert_has(".title", "LiveView main page")
      |> assert_has("[data-role='title']", "LiveView main page")
    end

    test "succeeds if more than one element matches selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", "Aragorn")
    end

    test "succeeds if more than one element matches selector and text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", "Multiple links")
    end

    test "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", "Has extra space")
    end

    test "succeeds when a non-200 status code is returned", %{conn: conn} do
      conn
      |> visit("/page/unauthorized")
      |> assert_has("h1", "Unauthorized")
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#nonexistent-id", "Main page")
      end
    end

    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find element with text "Super page".

        Found other elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("h1", "Super page")
      end
    end

    test "can be used to assert on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title", "PhoenixTest is the best!")
    end

    test "can be used to assert on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", "PhoenixTest is the best!")
    end

    test "raises if title does not match expected value (Static)", %{conn: conn} do
      msg =
        """
        Expected title to be "Not the title" but got "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("title", "Not the title")
      end
    end

    test "raises if title does not match expected value (Live)", %{conn: conn} do
      msg =
        """
        Expected title to be "Not the title" but got "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/live/index")
        |> assert_has("title", "Not the title")
      end
    end

    test "raises if title is contained but is not exactly the same as expected", %{conn: conn} do
      msg =
        """
        Expected title to be "PhoenixTest" but got "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("title", "PhoenixTest")
      end
    end

    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find element with text "Frodo".

        Found other elements matching the selector "#multiple-items":

        <ul id="multiple-items">
          <li>
            Aragorn
          </li>
          <li>
            Legolas
          </li>
          <li>
            Gimli
          </li>
        </ul>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#multiple-items", "Frodo")
      end
    end
  end

  describe "refute_has/2" do
    test "succeeds if no element is found with CSS selector (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test "succeeds if no element is found with CSS selector (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test "can refute presence of title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index_no_layout")
      |> refute_has("title")
      |> refute_has("#something-else-to-test-pipe")
    end

    test "raises if element is found", %{conn: conn} do
      msg =
        """
        Expected not to find an element.

        But found an element with selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1")
      end
    end

    test "raises if title is found", %{conn: conn} do
      msg =
        """
        Expected title not to be present but found: "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("title")
      end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find an element.

        But found 2 elements with selector ".multiple_links":
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links")
      end
    end
  end

  describe "refute_has/3" do
    test "can be used to refute on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("title", "Not the title")
      |> refute_has("title", "Not this title either")
    end

    test "can be used to refute on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", "Not the title")
      |> refute_has("title", "Not this title either")
    end

    test "raises if title matches value (Static)", %{conn: conn} do
      msg =
        """
        Expected title not to be "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("title", "PhoenixTest is the best!")
      end
    end

    test "raises if title matches value (Live)", %{conn: conn} do
      msg =
        """
        Expected title not to be "PhoenixTest is the best!"
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/live/index")
        |> refute_has("title", "PhoenixTest is the best!")
      end
    end

    test "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", "Not main page")
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", "Main page")
      |> refute_has("#title", "Not main page")
    end

    test "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("h1", "Not main page")
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", "Main page")
      |> refute_has("#title", "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find an element.

        But found an element with selector "#title" and text "Main page":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has("#title", "Main page")
      end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find an element.

        But found 2 elements with selector ".multiple_links" and text "Multiple links":

        <a class="multiple_links" href="/page/page_3">
          Multiple links
        </a>

        <a class="multiple_links" href="/page/page_4">
          Multiple links
        </a>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links", "Multiple links")
      end
    end
  end
end
