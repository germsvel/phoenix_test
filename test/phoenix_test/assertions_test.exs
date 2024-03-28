defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers
  import PhoenixTest.Selectors

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

    test "succeeds if more than one element matches selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("li")
    end

    test "takes in input helper in assertion", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(input(type: "text", label: "User Name"))
    end
  end

  describe "assert_has/3" do
    test "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
      |> assert_has("#title", text: "Main page")
      |> assert_has(".title", text: "Main page")
      |> assert_has("[data-role='title']", text: "Main page")
    end

    test "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> assert_has("#title", text: "LiveView main page")
      |> assert_has(".title", text: "LiveView main page")
      |> assert_has("[data-role='title']", text: "LiveView main page")
    end

    test "succeeds if more than one element matches selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", text: "Aragorn")
    end

    test "succeeds if more than one element matches selector and text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", text: "Multiple links")
    end

    test "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", text: "Has extra space")
    end

    test "succeeds when a non-200 status code is returned", %{conn: conn} do
      conn
      |> visit("/page/unauthorized")
      |> assert_has("h1", text: "Unauthorized")
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#nonexistent-id", text: "Main page")
      end
    end

    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find any elements with selector "h1" and text "Super page".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("h1", text: "Super page")
      end
    end

    test "can be used to assert on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    test "can be used to assert on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
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
        |> assert_has("title", text: "Not the title")
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
        |> assert_has("title", text: "Not the title")
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
        |> assert_has("title", text: "PhoenixTest")
      end
    end

    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find any elements with selector "#multiple-items" and text "Frodo".

        Found these elements matching the selector "#multiple-items":

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
        conn |> assert_has("#multiple-items", text: "Frodo")
      end
    end

    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", count: 2)
      |> assert_has(".multiple_links", text: "Multiple links", count: 2)
      |> assert_has("h1", count: 1)
      |> assert_has("h1", text: "Main page", count: 1)
    end

    test "raises an error if count is more than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      msg =
        """
        Expected 1 elements with ".multiple_links".

        But found 2:
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        session |> assert_has(".multiple_links", count: 1)
      end
    end

    test "raises an error if count is less than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      msg =
        """
        Expected 2 elements with "h1".

        But found 1:
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        session |> assert_has("h1", count: 2)
      end
    end

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main", exact: false)
      |> assert_has("h1", text: "Main page", exact: true)
    end

    test "raises if `exact` text doesn't match", %{conn: conn} do
      msg =
        """
        Could not find any elements with selector "h1" and text "Main".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("h1", text: "Main", exact: true)
      end
    end

    test "accepts an `at` option to assert on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("#multiple-items li", at: 2, text: "Legolas")
    end

    test "raises if it cannot find element at `at` position", %{conn: conn} do
      msg =
        """
        Could not find any elements with selector "#multiple-items li" and text "Aragorn" at position 2
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("#multiple-items li", at: 2, text: "Aragorn")
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

    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", count: 2)
      |> refute_has("h1", text: "Main page", count: 2)
      |> refute_has(".multiple_links", count: 1)
      |> refute_has(".multiple_links", text: "Multiple links", count: 1)
    end

    test "raises if element is found", %{conn: conn} do
      msg =
        """
        Expected not to find any elements with selector "h1".

        But found 1:

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
        Expected not to find any elements with selector ".multiple_links".

        But found 2:
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links")
      end
    end

    test "raises if there is one element and count is 1", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find 1 elements with selector "h1".
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has("h1", count: 1)
      end
    end

    test "raises if there are the same number of elements as refuted", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find 2 elements with selector ".multiple_links".

        But found 2:
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links", count: 2)
      end
    end
  end

  describe "refute_has/3" do
    test "can be used to refute on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", text: "Not this title either")
    end

    test "can be used to refute on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", text: "Not this title either")
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
        |> refute_has("title", text: "PhoenixTest is the best!")
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
        |> refute_has("title", text: "PhoenixTest is the best!")
      end
    end

    test "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#title", text: "Not main page")
    end

    test "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#title", text: "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find any elements with selector "#title" and text "Main page".

        But found 1:

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has("#title", text: "Main page")
      end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find any elements with selector ".multiple_links" and text "Multiple links".

        But found 2:

        <a class="multiple_links" href="/page/page_3">
          Multiple links
        </a>

        <a class="multiple_links" href="/page/page_4">
          Multiple links
        </a>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links", text: "Multiple links")
      end
    end

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Main", exact: true)
    end

    test "raises if `exact` text makes refutation false", %{conn: conn} do
      msg =
        """
        Expected not to find any elements with selector "h1" and text "Main".

        But found 1:

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1", text: "Main", exact: false)
      end
    end

    test "accepts an `at` option to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#multiple-items li", at: 2, text: "Aragorn")
    end

    test "raises if it finds element at `at` position", %{conn: conn} do
      msg =
        """
        Expected not to find any elements with selector "#multiple-items li" and text "Legolas" at position 2

        But found 1:

        <li>
          Legolas
        </li>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("#multiple-items li", at: 2, text: "Legolas")
      end
    end
  end
end
