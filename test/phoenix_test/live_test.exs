defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers
  import PhoenixTest.Selectors

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
      |> assert_has("h1", text: "LiveView main page")
    end

    test "follows redirects", %{conn: conn} do
      conn
      |> visit("/live/redirect_on_mount/redirect")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "follows push redirects (push navigate)", %{conn: conn} do
      conn
      |> visit("/live/redirect_on_mount/push_navigate")
      |> assert_has("h1", text: "LiveView main page")
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
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "accepts click_link with selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("a", "Navigate link")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "handles patches to current view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Patch link")
      |> assert_has("h2", text: "LiveView main page details")
    end

    test "handles navigation to a non-liveview", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_has("h1", text: "Main page")
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
      |> assert_has("#tab", text: "Tab title")
    end

    test "does not remove active form if button isn't form's submit button", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> fill_in("User Name", with: "Aragorn")
        |> click_button("Reset")

      assert PhoenixTest.ActiveForm.active?(session.active_form)
    end

    test "resets active form if it is form's submit button", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> fill_in("User Name", with: "Aragorn")
        |> click_button("Save Nested Form")

      refute PhoenixTest.ActiveForm.active?(session.active_form)
    end

    test "includes name and value if specified", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "no-phx-change-form-button: save")
    end

    test "includes default data if form is untouched", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "contact: mail")
      |> assert_has("#form-data", text: "full_form_button: save")
    end

    test "raises an error when there are no buttons on page", %{conn: conn} do
      msg = ~r/Could not find element with selector "button" and text "Show tab"/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/page_2")
        |> click_button("Show tab")
      end
    end

    test "raises an error if button is not part of form and has no phx-submit", %{conn: conn} do
      msg = """
      Expected element with selector "button" and text "Actionless Button" to have a `phx-click` attribute or belong to a `form` element.
      """

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> click_button("Actionless Button")
      end
    end

    test "raises an error if active form but can't find button", %{conn: conn} do
      msg = ~r/Could not find element with selector "button" and text "No button"/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_form("#no-phx-change-form", name: "Legolas")
        |> click_button("No button")
      end
    end
  end

  describe "fill_in/3" do
    test "fills in a single text field based on the label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "someone@example.com")
      |> assert_has(input(label: "Email", value: "someone@example.com"))
    end

    test "can fill-in complex form fields", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Aragorn")
      |> fill_in("Notes", with: "Dunedain. Heir to the throne. King of Arnor and Gondor")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "first_name: Aragorn")
      |> assert_has("#form-data",
        text: "notes: Dunedain. Heir to the throne. King of Arnor and Gondor"
      )
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
    end

    test "triggers phx-change validations", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: nil)
      |> assert_has("#form-errors", text: "Errors present")
    end

    test "can be used to submit form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "someone@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end
  end

  describe "select/3" do
    test "selects given option for a label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> assert_has("#full-form option[value='elf']")
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("False", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:admin: false")
    end

    test "can be used to submit form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race: elf")
    end
  end

  describe "check/2" do
    test "checks a checkbox", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end
  end

  describe "uncheck/2" do
    test "sends the default value (in hidden input)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end
  end

  describe "choose/2" do
    test "chooses an option in radio button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> choose("Email Choice")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: email")
    end

    test "uses the default 'checked' if present", %{conn: conn} do
      conn
      |> visit("/live/index")
      # other field to trigger form save
      |> fill_in("First Name", with: "Not important")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: mail")
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
      |> assert_has("#form-errors", text: "Errors present")
    end

    test "can be combined with other fill_forms without click_button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#country-form", country: "Bolivia")
      |> fill_form("#city-form", city: "La Paz")
      |> assert_has("#form-data", text: "Bolivia: La Paz")
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
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: some@example.com")
    end

    test "can handle clicking button that does not submit form after fill_form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#email-form", email: "some@example.com")
      |> click_button("Save Nested Form")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test "can handle forms with inputs, checkboxes, selects, textboxes", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#full-form",
        first_name: "Aragorn",
        admin: "on",
        race: "human",
        notes: "King of Gondor"
      )
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data", text: "admin: on")
      |> assert_has("#form-data", text: "race: human")
      |> assert_has("#form-data", text: "notes: King of Gondor")
    end

    test "can submit nested forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#nested-form", user: %{name: "Aragorn"})
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#redirect-form", name: "Aragorn")
      |> click_button("#redirect-form-submit", "Save Redirect Form")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#redirect-form-to-static", name: "Aragorn")
      |> click_button("#redirect-form-to-static-submit", "Save Redirect to Static")
      |> assert_has("h1", text: "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#non-liveview-form", name: "Aragorn")
      |> click_button("Submit Non LiveView")
      |> assert_has("h1", text: "Main page")
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
      |> assert_has("#form-data", text: "email: some@example.com")
    end

    test "includes pre-rendered data (input value, selected option, checked checkbox, checked radio button) via phx-submit",
         %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#pre-rendered-data-form", [])
      |> assert_has("#form-data", text: "input: value")
      |> assert_has("#form-data", text: "select: selected")
      |> assert_has("#form-data", text: "select_none_selected: first")
      |> assert_has("#form-data", text: "checkbox: checked")
      |> assert_has("#form-data", text: "radio: checked")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#redirect-form", name: "Aragorn")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#redirect-form-to-static", name: "Aragorn")
      |> assert_has("h1", text: "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#non-liveview-form", name: "Aragorn")
      |> assert_has("h1", text: "Main page")
    end

    test "includes pre-rendered data (input value, selected option, checked checkbox, checked radio button) in regular (non phx-submit) form",
         %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#pre-rendered-data-non-liveview-form", [])
      |> assert_has("#form-data", text: "input: value")
      |> assert_has("#form-data", text: "select: selected")
      |> assert_has("#form-data", text: "select_none_selected: first")
      |> assert_has("#form-data", text: "checkbox: checked")
      |> assert_has("#form-data", text: "radio: checked")
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

  describe "open_browser" do
    setup do
      open_fun = fn view ->
        assert %Phoenix.LiveViewTest.View{} = view
      end

      %{open_fun: open_fun}
    end

    test "opens the browser", %{conn: conn, open_fun: open_fun} do
      conn
      |> visit("/live/index")
      |> open_browser(open_fun)
      |> assert_has("h1", text: "LiveView main page")
    end
  end
end
