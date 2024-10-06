defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true
  use PhoenixTest.Case, playwright: :chromium

  import PhoenixTest
  import PhoenixTest.Locators
  import PhoenixTest.TestHelpers

  alias ExUnit.AssertionError
  alias PhoenixTest.Live

  describe "assert_has/2" do
    test_also_with_playwright "succeeds if single element is found with CSS selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("[data-role='title']")
    end

    # TODO Playwright: Fix error message
    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "#nonexistent-id")
      end
    end

    # TODO Playwright: Fix special page title assertion
    test "succeeds if element searched is title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title")
    end

    # TODO Playwright: Fix special page title assertion
    test "succeeds if element searched is title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title")
    end

    test_also_with_playwright "succeeds if more than one element matches selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("li")
    end

    # TODO Playwright: Compile PhoenixTest locators
    test "takes in input helper in assertion", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(input(type: "text", label: "User Name"))
    end
  end

  describe "assert_has/3" do
    test_also_with_playwright "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
      |> assert_has("#title", text: "Main page")
      |> assert_has(".title", text: "Main page")
      |> assert_has("[data-role='title']", text: "Main page")
    end

    test_also_with_playwright "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> assert_has("#title", text: "LiveView main page")
      |> assert_has(".title", text: "LiveView main page")
      |> assert_has("[data-role='title']", text: "LiveView main page")
    end

    test_also_with_playwright "succeeds if more than one element matches selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", text: "Aragorn")
    end

    test_also_with_playwright "succeeds if more than one element matches selector and text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", text: "Multiple links")
    end

    test_also_with_playwright "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", text: "Has extra space")
    end

    test_also_with_playwright "succeeds when a non-200 status code is returned", %{conn: conn} do
      conn
      |> visit("/page/unauthorized")
      |> assert_has("h1", text: "Unauthorized")
    end

    # TODO Playwright: Fix error message
    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "#nonexistent-id", text: "Main page")
      end
    end

    # TODO Playwright: Fix error message
    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Could not find any elements with selector "h1" and text "Super page".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "h1", text: "Super page")
      end
    end

    # TODO Playwright: Fix special page title assertion
    test "can be used to assert on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    # TODO Playwright: Fix special page title assertion
    test "can be used to assert on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    # TODO Playwright: Fix special page title assertion
    test "can assert title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!", exact: true)
    end

    # TODO Playwright: Fix error message
    test "raises if title does not match expected value (Static)", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title to be "Not the title" but got "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("title", text: "Not the title")
      end
    end

    # TODO Playwright: Fix error message
    test "raises if title does not match expected value (Live)", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title to be "Not the title" but got "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/live/index")
        |> assert_has("title", text: "Not the title")
      end
    end

    # TODO Playwright: Fix error message
    test "raises if title is contained but is not exactly the same as expected (with exact=true)",
         %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title to be "PhoenixTest" but got "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("title", text: "PhoenixTest", exact: true)
      end
    end

    # TODO Playwright: Fix error message
    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
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
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "#multiple-items", text: "Frodo")
      end
    end

    # TODO Playwright: Support count
    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", count: 2)
      |> assert_has(".multiple_links", text: "Multiple links", count: 2)
      |> assert_has("h1", count: 1)
      |> assert_has("h1", text: "Main page", count: 1)
    end

    # TODO Playwright: Fix error message
    test "raises an error if count is more than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected 1 elements with ".multiple_links".

        But found 2:
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(session, ".multiple_links", count: 1)
      end
    end

    # TODO Playwright: Fix error message
    test "raises an error if count is less than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected 2 elements with "h1".

        But found 1:
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(session, "h1", count: 2)
      end
    end

    test_also_with_playwright "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main", exact: false)
      |> assert_has("h1", text: "Main page", exact: true)
    end

    # TODO Playwright: Fix error message
    test "raises if `exact` text doesn't match", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Could not find any elements with selector "h1" and text "Main".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("h1", text: "Main", exact: true)
      end
    end

    # TODO Fix: Evaluate both at and text options (there is only one Legolas text)
    test "accepts an `at` option to assert on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("#multiple-items li", at: 2, text: "Legolas")
    end

    # TODO Playwright: Fix error message
    test "raises if it cannot find element at `at` position", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Could not find any elements with selector "#multiple-items li" and text "Aragorn" at position 2
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> assert_has("#multiple-items li", at: 2, text: "Aragorn")
      end
    end
  end

  describe "refute_has/2" do
    test_also_with_playwright "succeeds if no element is found with CSS selector (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test_also_with_playwright "succeeds if no element is found with CSS selector (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test_also_with_playwright "can refute presence of title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index_no_layout")
      |> refute_has("title")
      |> refute_has("#something-else-to-test-pipe")
    end

    # TODO Playwright: Support 'count'
    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", count: 2)
      |> refute_has("h1", text: "Main page", count: 2)
      |> refute_has(".multiple_links", count: 1)
      |> refute_has(".multiple_links", text: "Multiple links", count: 1)
    end

    # TODO Playwright: Fix error message
    test "raises if element is found", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "h1".

        But found 1:

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1")
      end
    end

    # TODO Playwright: Fix error message
    test "raises if title is found", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title not to be present but found: "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("title")
      end
    end

    # TODO Playwright: Fix error message
    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector ".multiple_links".

        But found 2:
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, ".multiple_links")
      end
    end

    # TODO Playwright: Fix error message
    test "raises if there is one element and count is 1", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find 1 elements with selector "h1".
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, "h1", count: 1)
      end
    end

    # TODO Playwright: Fix error message
    test "raises if there are the same number of elements as refuted", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find 2 elements with selector ".multiple_links".

        But found 2:
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, ".multiple_links", count: 2)
      end
    end
  end

  describe "refute_has/3" do
    test_also_with_playwright "can be used to refute on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", text: "Not this title either")
    end

    test_also_with_playwright "can be used to refute on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", text: "Not this title either")
    end

    test_also_with_playwright "can be used to refute page title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "PhoenixTest is the", exact: true)
    end

    # TODO Playwright: Fix error message
    test "raises if title matches value (Static)", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title not to be "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("title", text: "PhoenixTest is the best!")
      end
    end

    # TODO Playwright: Fix error message
    test "raises if title matches value (Live)", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected title not to be "PhoenixTest is the best!"
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/live/index")
        |> refute_has("title", text: "PhoenixTest is the best!")
      end
    end

    test_also_with_playwright "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#title", text: "Not main page")
    end

    test_also_with_playwright "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#title", text: "Not main page")
    end

    # TODO Playwright: Fix error message
    test "raises an error if one element is found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "#title" and text "Main page".

        But found 1:

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, "#title", text: "Main page")
      end
    end

    # TODO Playwright: Fix error message
    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector ".multiple_links" and text "Multiple links".

        But found 2:

        <a class="multiple_links" href="/page/page_3">
          Multiple links
        </a>

        <a class="multiple_links" href="/page/page_4">
          Multiple links
        </a>
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, ".multiple_links", text: "Multiple links")
      end
    end

    test_also_with_playwright "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Main", exact: true)
    end

    # TODO Playwright: Fix error message
    test "raises if `exact` text makes refutation false", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "h1" and text "Main".

        But found 1:

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1", text: "Main", exact: false)
      end
    end

    test_also_with_playwright "accepts an `at` option (without text) to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#single-list-item li", at: 2)
    end

    test_also_with_playwright "accepts an `at` option with text to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#multiple-items li", at: 2, text: "Aragorn")
    end

    # TODO Playwright: Fix error message
    test "raises if it finds element at `at` position", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "#multiple-items li" and text "Legolas" at position 2

        But found 1:

        <li>
          Legolas
        </li>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("#multiple-items li", at: 2, text: "Legolas")
      end
    end
  end

  describe "assert_path" do
    test_also_with_playwright "asserts the session's current path" do
      session = %Live{current_path: "/page/index"}

      assert_path(session, "/page/index")
    end

    test_also_with_playwright "asserts query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      assert_path(session, "/page/index", query_params: %{"hello" => "world"})
    end

    test_also_with_playwright "order of query params does not matter" do
      session = %Live{current_path: "/page/index?hello=world&foo=bar"}

      assert_path(session, "/page/index", query_params: %{"foo" => "bar", "hello" => "world"})
    end

    # TODO Playwright: Fix error message
    test "raises helpful error if path doesn't match" do
      msg =
        ignore_whitespace("""
        Expected path to be "/page/not-index" but got "/page/index"
        """)

      assert_raise AssertionError, msg, fn ->
        session = %Live{current_path: "/page/index"}

        assert_path(session, "/page/not-index")
      end
    end

    # TODO Playwright: Fix error message
    test "raises helpful error if path doesn't have query params" do
      msg =
        ignore_whitespace("""
        Expected query params to be "details=true&foo=bar" but got nil
        """)

      assert_raise AssertionError, msg, fn ->
        session = %Live{current_path: "/page/index"}

        assert_path(session, "/page/index", query_params: %{foo: "bar", details: true})
      end
    end

    # TODO Playwright: Fix error message
    test "raises helpful error if query params don't match" do
      msg =
        ignore_whitespace("""
        Expected query params to be "goodbye=world&hi=bye" but got "hello=world&hi=bye"
        """)

      assert_raise AssertionError, msg, fn ->
        session = %Live{current_path: "/page/index?hello=world&hi=bye"}

        assert_path(session, "/page/index", query_params: %{"goodbye" => "world", "hi" => "bye"})
      end
    end
  end

  describe "refute_path" do
    test_also_with_playwright "refute the given path is the current path" do
      session = %Live{current_path: "/page/index"}

      refute_path(session, "/page/page_2")
    end

    test_also_with_playwright "refutes query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      refute_path(session, "/page/index", query_params: %{"hello" => "not-world"})
    end

    # TODO Playwright: Fix error message
    test "raises helpful error if path matches" do
      msg =
        ignore_whitespace("""
        Expected path not to be "/page/index"
        """)

      assert_raise AssertionError, msg, fn ->
        session = %Live{current_path: "/page/index"}

        refute_path(session, "/page/index")
      end
    end

    # TODO Playwright: Fix error message
    test "raises helpful error if query params MATCH" do
      msg =
        ignore_whitespace("""
        Expected query params not to be "hello=world&hi=bye"
        """)

      assert_raise AssertionError, msg, fn ->
        session = %Live{current_path: "/page/index?hello=world&hi=bye"}

        refute_path(session, "/page/index", query_params: %{"hello" => "world", "hi" => "bye"})
      end
    end
  end
end
