defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers

  alias PhoenixTest.Driver

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "render_page_title/1" do
    test "renders the page title", %{conn: conn} do
      title =
        conn
        |> visit("/live/index")
        |> PhoenixTest.Driver.render_page_title()

      assert title == "PhoenixTest is the best!"
    end

    test "renders updated page title", %{conn: conn} do
      title =
        conn
        |> visit("/live/index")
        |> click_button("Change page title")
        |> PhoenixTest.Driver.render_page_title()

      assert title == "Title changed!"
    end

    test "returns nil if page title isn't found", %{conn: conn} do
      title =
        conn
        |> visit("/live/index_no_layout")
        |> PhoenixTest.Driver.render_page_title()

      assert title == nil
    end
  end

  describe "visit/2" do
    test "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", "LiveView main page")
    end

    test "raises error if route doesn't exist", %{conn: conn} do
      assert_raise Phoenix.Router.NoRouteError, fn ->
        conn
        |> visit("/live/non_route")
      end
    end
  end

  describe "click_link/2" do
    test "follows 'navigate' links", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_has("h1", "LiveView page 2")
    end

    test "accepts click_link with selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("a", "Navigate link")
      |> assert_has("h1", "LiveView page 2")
    end

    test "handles patches to current view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Patch link")
      |> assert_has("h2", "LiveView main page details")
    end

    test "handles navigation to a non-liveview", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_has("h1", "Main page")
    end

    test "raises error when there are multiple links with same text", %{conn: conn} do
      assert_raise ArgumentError, ~r/2 of them matched the text filter/, fn ->
        conn
        |> visit("/live/index")
        |> click_link("Multiple links")
      end
    end

    test "raises an error when link element can't be found with given text", %{conn: conn} do
      assert_raise ArgumentError, ~r/elements but none matched the text filter "No link"/, fn ->
        conn
        |> visit("/live/index")
        |> click_link("No link")
      end
    end

    test "raises an error when there are no links on the page", %{conn: conn} do
      assert_raise ArgumentError, ~r/selector "a" did not return any element/, fn ->
        conn
        |> visit("/live/page_2")
        |> click_link("No link")
      end
    end
  end

  describe "click_button/2" do
    test "handles a `phx-click` button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Show tab")
      |> assert_has("#tab", "Tab title")
    end

    test "raises an error when there are no buttons on page", %{conn: conn} do
      assert_raise ArgumentError, ~r/selector "button" did not return any element/, fn ->
        conn
        |> visit("/live/page_2")
        |> click_button("Show tab")
      end
    end

    test "raises an error if no active form and no phx-submit", %{conn: conn} do
      assert_raise ArgumentError, ~r/does not have phx-click attribute/, fn ->
        conn
        |> visit("/live/index")
        |> click_button("Save email")
      end
    end

    test "raises an error if active form but can't find button", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find an element with given selector/, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#no-phx-change-form", name: "Legolas")
        |> click_button("No button")
      end
    end
  end

  describe "fill_form/3" do
    test "does not trigger phx-change event if one isn't present", %{conn: conn} do
      session = conn |> visit("/live/index")

      starting_html = Driver.render_html(session)

      ending_html =
        session
        |> fill_form("#no-phx-change-form", name: "Aragorn")
        |> Driver.render_html()

      assert starting_html == ending_html
    end

    test "triggers a phx-change event on a form (when it has one)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#email-form", email: nil)
      |> assert_has("#form-errors", "Errors present")
    end

    test "raises an error when form can't be found with selector", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#no-existing-form", email: "some@example.com")
      end
    end

    test "raises an error when inputs aren't found", %{conn: conn} do
      assert_raise ArgumentError, ~r/could not find non-disabled input, select or textarea/, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#email-form", member_of_fellowship: false)
      end
    end

    test "raises an error when inputs aren't found in form without phx-change", %{conn: conn} do
      msg = """
      Expected form to have "member_of_fellowship" form field, but found none.

      Found the following fields:

      <input name="name"/>\n
      """

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#no-phx-change-form", member_of_fellowship: false)
      end
    end
  end

  describe "fill_form + click_button" do
    test "fill_form can be combined with click_button to submit a form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#email-form", email: "some@example.com")
      |> click_button("Save")
      |> assert_has("#form-data", "email: some@example.com")
    end

    test "can handle forms with inputs, checkboxes, selects, textboxes", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#full-form",
        name: "Aragorn",
        admin: "on",
        race: "human",
        notes: "King of Gondor"
      )
      |> click_button("Save")
      |> assert_has("#form-data", "name: Aragorn")
      |> assert_has("#form-data", "admin: on")
      |> assert_has("#form-data", "race: human")
      |> assert_has("#form-data", "notes: King of Gondor")
    end

    test "can submit nested forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#nested-form", user: %{name: "Aragorn"})
      |> click_button("#nested-form", "Save")
      |> assert_has("#form-data", "user:name: Aragorn")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#redirect-form", name: "Aragorn")
      |> click_button("#redirect-form-submit", "Save")
      |> assert_has("h1", "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#redirect-form-to-static", name: "Aragorn")
      |> click_button("#redirect-form-to-static-submit", "Save")
      |> assert_has("h1", "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#non-liveview-form", name: "Aragorn")
      |> click_button("Submit Non LiveView")
      |> assert_has("h1", "Main page")
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg =
        """
        Expected form with selector "#invalid-form" to have a `phx-submit` or `action` defined.
        """
        |> ignore_whitespace()

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#invalid-form", name: "Aragorn")
        |> click_button("Submit Invalid Form")
      end
    end
  end

  describe "submit_form/3" do
    test "submits a form via phx-submit", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#email-form", email: "some@example.com")
      |> assert_has("#form-data", "email: some@example.com")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#redirect-form", name: "Aragorn")
      |> assert_has("h1", "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#redirect-form-to-static", name: "Aragorn")
      |> assert_has("h1", "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#non-liveview-form", name: "Aragorn")
      |> assert_has("h1", "Main page")
    end

    test "raises an error if the form can't be found", %{conn: conn} do
      message = ~r/Could not find element with selector "#no-existing-form"/

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/live/index")
        |> submit_form("#no-existing-form", email: "some@example.com")
      end
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg =
        """
        Expected form with selector "#invalid-form" to have a `phx-submit` or `action` defined.
        """
        |> ignore_whitespace()

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> submit_form("#invalid-form", name: "Aragorn")
      end
    end

    test "raises an error if a field can't be found", %{conn: conn} do
      message = ~r/could not find non-disabled input, select or textarea/

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/live/index")
        |> submit_form("#no-phx-change-form", member_of_fellowship: false)
      end
    end
  end
end
