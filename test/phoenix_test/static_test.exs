defmodule PhoenixTest.StaticTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "render_page_title/1" do
    test "renders the page title", %{conn: conn} do
      title =
        conn
        |> visit("/page/index")
        |> PhoenixTest.Driver.render_page_title()

      assert title == "PhoenixTest is the best!"
    end

    test "renders nil if there's no page title", %{conn: conn} do
      title =
        conn
        |> visit("/page/index_no_layout")
        |> PhoenixTest.Driver.render_page_title()

      assert title == nil
    end
  end

  describe "visit/2" do
    test "navigates to given static page", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", "Main page")
    end

    test "follows redirects", %{conn: conn} do
      conn
      |> visit("/page/redirect_to_static")
      |> assert_has("h1", "Main page")
    end

    test "raises error if route doesn't exist", %{conn: conn} do
      assert_raise Phoenix.Router.NoRouteError, fn ->
        conn
        |> visit("/non_route")
      end
    end
  end

  describe "click_link/2" do
    test "follows link's path", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Page 2")
      |> assert_has("h1", "Page 2")
    end

    test "accepts selector for link", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("a", "Page 2")
      |> assert_has("h1", "Page 2")
    end

    test "handles navigation to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("To LiveView!")
      |> assert_has("h1", "LiveView main page")
    end

    test "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Data-method Delete")
      |> assert_has("h1", "Record deleted")
    end

    test "raises error if trying to submit via `data-` attributes but incomplete", %{conn: conn} do
      msg =
        """
        Tried submitting form via `data-method` but some data attributes are
        missing.

        I expected "a" with text "Incomplete data-method Delete" to include
        data-method, data-to, and data-csrf.

        I found:

        <a href="/users/2" data-method="delete">
          Incomplete data-method Delete
        </a>

        It seems these are missing: data-to, data-csrf.

        NOTE: `data-method` form submissions happen through JavaScript. Tests
        emulate that, but be sure to verify you're including Phoenix.HTML.js!

        See: https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#module-javascript-library
        """
        |> ignore_whitespace()

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_link("Incomplete data-method Delete")
      end
    end

    test "raises error when there are multiple links with same text", %{conn: conn} do
      assert_raise ArgumentError, ~r/Found more than one element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_link("Multiple links")
      end
    end

    test "raises an error when link element can't be found with given text", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_link("No link")
      end
    end

    test "raises an error when there are no links on the page", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/page_2")
        |> click_link("No link")
      end
    end
  end

  describe "click_button/2" do
    test "handles a button that defaults to GET", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Get record")
      |> assert_has("h1", "Record received")
    end

    test "accepts selector for button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("button", "Get record")
      |> assert_has("h1", "Record received")
    end

    test "handles a button clicks when button PUTs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Mark as active")
      |> assert_has("h1", "Record updated")
    end

    test "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", "Record deleted")
    end

    test "can handle redirects to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Post and Redirect")
      |> assert_has("h1", "LiveView main page")
    end

    test "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Data-method Delete")
      |> assert_has("h1", "Record deleted")
    end

    test "raises error if trying to submit via `data-` attributes but incomplete", %{conn: conn} do
      msg =
        """
        Tried submitting form via `data-method` but some data attributes are
        missing.

        I expected "button" with text "Incomplete data-method Delete" to include
        data-method, data-to, and data-csrf.

        I found:

        <button data-method="delete">
          Incomplete data-method Delete
        </button>

        It seems these are missing: data-to, data-csrf.

        NOTE: `data-method` form submissions happen through JavaScript. Tests
        emulate that, but be sure to verify you're including Phoenix.HTML.js!

        See: https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#module-javascript-library
        """
        |> ignore_whitespace()

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_button("Incomplete data-method Delete")
      end
    end

    test "raises an error when there are no buttons on page", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find an element with given selector/, fn ->
        conn
        |> visit("/page/page_2")
        |> click_button("Show tab")
      end
    end

    test "raises an error if can't find button", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find an element with given selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_button("No button")
      end
    end
  end

  describe "fill_form/3" do
    test "raises an error when form cannot be found with given selector", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> fill_form("#no-existing-form", name: "Aragorn")
      end
    end

    test "raises an error when form input cannot be found", %{conn: conn} do
      message =
        """
        Expected form to have "location[user][name]" form field, but found none.

        Found the following fields:

        <input name="user[name]"/>\n
        """

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/page/index")
        |> fill_form("#nested-form", location: %{user: %{name: "Aragorn"}})
      end
    end
  end

  describe "fill_form + click_button" do
    test "can submit forms with input type submit", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#email-form", email: "sample@example.com")
      |> click_button("#email-form", "Save")
      |> assert_has("#form-data", "email: sample@example.com")
    end

    test "can submit nested forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#nested-form", user: %{name: "Aragorn"})
      |> click_button("#nested-form", "Save")
      |> assert_has("#form-data", "user:name: Aragorn")
    end

    test "can submit forms with inputs, checkboxes, selects, textboxes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#full-form",
        name: "Aragorn",
        admin: "on",
        race: "human",
        notes: "King of Gondor",
        member_of_fellowship: "on"
      )
      |> click_button("Save")
      |> assert_has("#form-data", "name: Aragorn")
      |> assert_has("#form-data", "admin: on")
      |> assert_has("#form-data", "race: human")
      |> assert_has("#form-data", "notes: King of Gondor")
      |> assert_has("#form-data", "member_of_fellowship: on")
    end

    test "can handle redirects into a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#redirect-to-liveview-form", name: "Aragorn")
      |> click_button("Save and Redirect to LiveView")
      |> assert_has("h1", "LiveView main page")
    end
  end

  describe "submit_form/3" do
    test "submits form even if no submit is present (acts as <Enter>)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#no-submit-button-form", name: "Aragorn")
      |> assert_has("#form-data", "name: Aragorn")
    end

    test "can handle redirects", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#no-submit-button-and-redirect", name: "Aragorn")
      |> assert_has("h1", "LiveView main page")
    end

    test "handles when form PUTs data through hidden input", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#update-form", name: "Aragorn")
      |> assert_has("#form-data", "name: Aragorn")
    end

    test "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", "Record deleted")
    end

    test "raises an error if the form can't be found", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> submit_form("#no-existing-form", email: "some@example.com")
      end
    end

    test "raises an error if a field can't be found", %{conn: conn} do
      assert_raise ArgumentError,
                   ~r/Expected form to have "member_of_fellowship" form field/,
                   fn ->
                     conn
                     |> visit("/page/index")
                     |> submit_form("#email-form", member_of_fellowship: false)
                   end
    end
  end

  describe "open_browser" do
    setup do
      open_fun = fn path ->
        assert content = File.read!(path)

        assert content =~
                 ~r[<link rel="stylesheet" href="file:.*phoenix_test\/priv\/assets\/app\.css"\/>]

        assert content =~ "<link rel=\"stylesheet\" href=\"//example.com/cool-styles.css\"/>"
        assert content =~ "body { font-size: 12px; }"

        assert content =~ ~r/<h1.*Main page/

        refute content =~ "<script>"
        refute content =~ "console.log(\"Hey, I'm some JavaScript!\")"
        refute content =~ "</script>"

        path
      end

      %{open_fun: open_fun}
    end

    test "opens the browser ", %{conn: conn, open_fun: open_fun} do
      conn
      |> visit("/page/index")
      |> open_browser(open_fun)
      |> assert_has("h1", "Main page")
    end
  end
end
