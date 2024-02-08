defmodule PhoenixTest.StaticTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given static page", %{conn: conn} do
      conn
      |> visit("/page/index")
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

    test "raises error when there are multiple links with same text", %{conn: conn} do
      assert_raise ArgumentError, ~r/Found more than one element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_link("Multiple links")
      end
    end

    test "handles navigation to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("To LiveView!")
      |> assert_has("h1", "LiveView main page")
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

    test "handles a button clicks when button PUTs data", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Mark as active")
      |> assert_has("h1", "Marked active!")
    end

    test "handles a button clicks when button DELETEs data", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", "Record deleted")
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
    test "can submit forms with input type submit", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#email-form", email: "sample@example.com")
      |> click_button("Save")
      |> assert_has("#form-data", "email: sample@example.com")
    end

    test "can submit nested forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#nested-form", user: %{name: "Aragorn"})
      |> click_button("Save")
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

    test "raises an error when form cannot be found with given selector", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> fill_form("#no-existing-form", name: "Aragorn")
      end
    end

    test "raises an error when form input cannot be found", %{conn: conn} do
      message = """
      Expected form to have "location[user][name]" form field, but found none.

      Found the following fields:

       - input with name="user[name]"
      """

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/page/index")
        |> fill_form("#nested-form", location: %{user: %{name: "Aragorn"}})
      end
    end
  end

  describe "submit_form/3" do
    test "submits form even if no submit is present (acts as <Enter>)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#no-submit-button-form", name: "Aragorn")
      |> assert_has("#form-data", "name: Aragorn")
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
end
