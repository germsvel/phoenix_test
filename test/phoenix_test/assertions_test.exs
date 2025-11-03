defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers

  alias ExUnit.AssertionError
  alias PhoenixTest.Live

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
        assert_has(conn, "#nonexistent-id")
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

    test "succeeds when asserting by value", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", value: "Frodo")
    end

    test "succeeds when searching by value and implicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", label: "Hobbit", value: "Frodo")
    end

    test "succeeds when searching by value and explicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", label: "Wizard", value: "Gandalf")
    end

    test "succeeds when selector matches either node with text, or any ancestor", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("label", text: "Country")
      |> assert_has("#country-form", text: "Country")
      |> assert_has("[data-phx-main]", text: "Country")
    end

    test "raises an error if value cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      msg = ~r/Could not find any elements with selector "input" and value "does-not-exist"/

      assert_raise AssertionError, msg, fn ->
        assert_has(session, "input", value: "does-not-exist")
      end
    end

    test "raises an error if label and value are found more than expected", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      assert_has(session, "input", label: "Kingdoms", value: "Gondor")
      assert_has(session, "input", label: "Kingdoms", value: "Gondor", count: 2)

      assert_raise AssertionError, ~r/with "input" and value "Gondor" with label "Kingdoms"/, fn ->
        assert_has(session, "input", label: "Kingdoms", value: "Gondor", count: 1)
      end
    end

    test "raises an error if label (with value) cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      msg = ~r/with selector "input" and value "Frodo" with label "Halfling"/

      assert_raise AssertionError, msg, fn ->
        assert_has(session, "input", label: "Halfling", value: "Frodo")
      end
    end

    test "raises an error if value (with label) cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      msg = ~r/with selector "input" and value "Sam" with label "Hobbit"/

      assert_raise AssertionError, msg, fn ->
        assert_has(session, "input", label: "Hobbit", value: "Sam")
      end
    end

    test "raises if user provides :text and :value options", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      assert_raise ArgumentError, ~r/Cannot provide both :text and :value/, fn ->
        assert_has(session, "div", text: "some text", value: "some value")
      end
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "#nonexistent-id", text: "Main page")
      end
    end

    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Could not find any elements with selector "h1" and text "Super page".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">Main page</h1>
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "h1", text: "Super page")
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

    test "can assert title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!", exact: true)
    end

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

    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Could not find any elements with selector "#multiple-items" and text "Frodo".

        Found these elements matching the selector "#multiple-items":

        <ul id="multiple-items">
          <li>Aragorn</li>
          <li>Legolas</li>
          <li>Gimli</li>
        </ul>
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(conn, "#multiple-items", text: "Frodo")
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
        ignore_whitespace("""
        Expected 1 element with ".multiple_links".

        But found 2:
        """)

      assert_raise AssertionError, msg, fn ->
        assert_has(session, ".multiple_links", count: 1)
      end
    end

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

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main", exact: false)
      |> assert_has("h1", text: "Main page", exact: true)
    end

    test "raises if `exact` text doesn't match", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Could not find any elements with selector "h1" and text "Main".

        Found these elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">Main page</h1>
        """)

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
      |> visit("/page/index")
      |> refute_has("title", text: "Not the title")
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
        ignore_whitespace("""
        Expected not to find any elements with selector "h1".

        But found 1:

        <h1 id="title" class="title" data-role="title">Main page</h1>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1")
      end
    end

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

    test "raises if there is one element and count is 1", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find 1 element with selector "h1".
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, "h1", count: 1)
      end
    end

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

    test "can be used to refute page title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "PhoenixTest is the", exact: true)
    end

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
        ignore_whitespace("""
        Expected not to find any elements with selector "#title" and text "Main page".

        But found 1:

        <h1 id="title" class="title" data-role="title">Main page</h1>
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, "#title", text: "Main page")
      end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector ".multiple_links" and text "Multiple links".

        But found 2:

        <a class="multiple_links" href="/page/page_3">Multiple links</a>
        <a class="multiple_links" href="/page/page_4">Multiple links</a>
        """)

      assert_raise AssertionError, msg, fn ->
        refute_has(conn, ".multiple_links", text: "Multiple links")
      end
    end

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Main", exact: true)
    end

    test "raises if `exact` text makes refutation false", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "h1" and text "Main".

        But found 1:

        <h1 id="title" class="title" data-role="title">Main page</h1>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("h1", text: "Main", exact: false)
      end
    end

    test "accepts an `at` option (without text) to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#single-list-item li", at: 2)
    end

    test "accepts an `at` option with text to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#multiple-items li", at: 2, text: "Aragorn")
    end

    test "raises if it finds element at `at` position", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected not to find any elements with selector "#multiple-items li" and text "Legolas" at position 2

        But found 1:

        <li>Legolas</li>
        """)

      assert_raise AssertionError, msg, fn ->
        conn
        |> visit("/page/index")
        |> refute_has("#multiple-items li", at: 2, text: "Legolas")
      end
    end

    test "can refute by value", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", value: "not-frodo")
    end

    test "can refute by value and implicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", label: "Halfling", value: "Frodo")
      |> refute_has("input", label: "Hobbit", value: "Sam")
    end

    test "can refute by value and explicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", label: "Istari", value: "Gandalf")
      |> refute_has("input", label: "Wizard", value: "Saruman")
    end

    test "raises an error if value is found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      msg = ~r/not to find any elements with selector "input" and value "Frodo"/

      assert_raise AssertionError, msg, fn ->
        refute_has(session, "input", value: "Frodo")
      end
    end

    test "raises an error if label and value are found more/less than expected", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      refute_has(session, "input", label: "Kingdoms", value: "Gondor", count: 1)

      assert_raise AssertionError, ~r/with selector "input" and value "Gondor" with label "Kingdoms"/, fn ->
        refute_has(session, "input", label: "Kingdoms", value: "Gondor")
      end
    end

    test "raises an error if label and value are found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      msg = ~r/with selector "input" and value "Frodo" with label "Hobbit"/

      assert_raise AssertionError, msg, fn ->
        refute_has(session, "input", label: "Hobbit", value: "Frodo")
      end
    end

    test "raises if user provides :text and :value options", %{conn: conn} do
      session = visit(conn, "/page/index")

      assert_raise ArgumentError, ~r/Cannot provide both :text and :value/, fn ->
        refute_has(session, "div", text: "some text", value: "some value")
      end
    end
  end

  describe "assert_path" do
    test "asserts the session's current path" do
      session = %Live{current_path: "/page/index"}

      assert_path(session, "/page/index")
    end

    test "asserts query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      assert_path(session, "/page/index", query_params: %{"hello" => "world"})
    end

    test "asserts wildcard in expected path" do
      session = %Live{current_path: "/user/12345/profile"}

      assert_path(session, "/user/*/profile")
    end

    test "order of query params does not matter" do
      session = %Live{current_path: "/page/index?hello=world&foo=bar"}

      assert_path(session, "/page/index", query_params: %{"foo" => "bar", "hello" => "world"})
    end

    test "handles query params that have a list as a value" do
      session = %Live{current_path: "/page/index?users[]=frodo&users[]=sam"}

      assert_path(session, "/page/index", query_params: %{"users" => ["frodo", "sam"]})
    end

    test "handles query params that have a map as a value" do
      session = %Live{current_path: "/page/index?filter[name]=frodo&filter[height]=1.24m"}

      assert_path(session, "/page/index", query_params: %{"filter" => %{"name" => "frodo", "height" => "1.24m"}})
    end

    test "handles asserting empty query params" do
      session = %Live{current_path: "/page/index"}

      assert_path(session, "/page/index", query_params: %{})
    end

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

    test "raises helpful error if path doesn't have query params with lists" do
      session = %Live{current_path: "/page/index?users[]=frodo&users[]=sam"}

      msg = ~r/Expected query params to be "users\[\]=sam" but/

      assert_raise AssertionError, msg, fn ->
        assert_path(session, "/page/index", query_params: %{"users" => ["sam"]})
      end
    end
  end

  describe "refute_path" do
    test "refute the given path is the current path" do
      session = %Live{current_path: "/page/index"}

      refute_path(session, "/page/page_2")
    end

    test "refutes query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      refute_path(session, "/page/index", query_params: %{"hello" => "not-world"})
    end

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
