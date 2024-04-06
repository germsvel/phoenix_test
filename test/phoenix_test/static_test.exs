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
      |> assert_has("h1", text: "Main page")
    end

    test "follows redirects", %{conn: conn} do
      conn
      |> visit("/page/redirect_to_static")
      |> assert_has("h1", text: "Main page")
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
      |> assert_has("h1", text: "Page 2")
    end

    test "accepts selector for link", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("a", "Page 2")
      |> assert_has("h1", text: "Page 2")
    end

    test "handles navigation to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("To LiveView!")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Data-method Delete")
      |> assert_has("h1", text: "Record deleted")
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
      |> assert_has("h1", text: "Record received")
    end

    test "accepts selector for button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("button", "Get record")
      |> assert_has("h1", text: "Record received")
    end

    test "handles a button clicks when button PUTs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Mark as active")
      |> assert_has("h1", text: "Record updated")
    end

    test "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", text: "Record deleted")
    end

    test "can handle redirects to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Post and Redirect")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Data-method Delete")
      |> assert_has("h1", text: "Record deleted")
    end

    test "does not remove active form if button isn't form's submit button", %{conn: conn} do
      session =
        conn
        |> visit("/page/index")
        |> fill_in("User Name", with: "Aragorn")
        |> click_button("Mark as active")

      assert PhoenixTest.ActiveForm.active?(session.active_form)
    end

    test "resets active form if it is form's submit button", %{conn: conn} do
      session =
        conn
        |> visit("/page/index")
        |> fill_in("User Name", with: "Aragorn")
        |> click_button("Save Nested Form")

      refute PhoenixTest.ActiveForm.active?(session.active_form)
    end

    test "includes name and value if specified", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "save-button: nested-form-save")
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
      msg = ~r/Could not find element with selector "button" and text "Show tab"/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/page_2")
        |> click_button("Show tab")
      end
    end

    test "raises an error if can't find button", %{conn: conn} do
      msg = ~r/Could not find element with selector "button" and text "No button"/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_button("No button")
      end
    end
  end

  describe "fill_in/3" do
    test "fills in a single text field based on the label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Email", with: "someone@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test "can fill-in complex form fields", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("First Name", with: "Aragorn")
      |> fill_in("Notes", with: "Dunedain. Heir to the throne. King of Arnor and Gondor")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data",
        text: "notes: Dunedain. Heir to the throne. King of Arnor and Gondor"
      )
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
    end
  end

  describe "select/3" do
    test "selects given option for a label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select("Elf", from: "Race")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race: elf")
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select("False", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:admin: false")
    end
  end

  describe "check/3" do
    test "checks a checkbox", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Admin (boolean)")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin_boolean: true")
    end

    test "sets checkbox value as 'on' by default", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end
  end

  describe "uncheck/3" do
    test "sends the default value (in hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end
  end

  describe "choose/2" do
    test "chooses an option in radio button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> choose("Email Choice")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: email")
    end

    test "uses the default 'checked' if present", %{conn: conn} do
      conn
      |> visit("/page/index")
      # other field to trigger form save
      |> fill_in("First Name", with: "Not important")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: mail")
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

        <input name="name"/>\n
        """

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/page/index")
        |> fill_form("#no-submit-button-form", location: %{user: %{name: "Aragorn"}})
      end
    end
  end

  describe "fill_form + click_button" do
    test "can submit forms with input type submit", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#email-form", email: "sample@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: sample@example.com")
    end

    test "can handle clicking button that does not submit form after fill_form", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#email-form", email: "some@example.com")
      |> click_button("Delete record")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test "can submit nested forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#nested-form", user: %{name: "Aragorn"})
      |> click_button("#nested-form", "Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
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
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data", text: "admin: on")
      |> assert_has("#form-data", text: "race: human")
      |> assert_has("#form-data", text: "notes: King of Gondor")
      |> assert_has("#form-data", text: "member_of_fellowship: on")
    end

    test "can handle redirects into a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_form("#redirect-to-liveview-form", name: "Aragorn")
      |> click_button("Save and Redirect to LiveView")
      |> assert_has("h1", text: "LiveView main page")
    end
  end

  describe "submit_form/3" do
    test "submits form even if no submit is present (acts as <Enter>)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#no-submit-button-form", name: "Aragorn")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test "can handle redirects", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#no-submit-button-and-redirect", name: "Aragorn")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "handles when form PUTs data through hidden input", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> submit_form("#update-form", name: "Aragorn")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", text: "Record deleted")
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
      |> assert_has("h1", text: "Main page")
    end
  end
end
