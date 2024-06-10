defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Selectors
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
        visit(conn, "/live/non_route")
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

    test "follows navigation that subsequently redirect", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate (and redirect back) link")
      |> assert_has("h1", text: "LiveView main page")
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
      |> assert_has("#form-data", text: "user:no-phx-change-form-button: save")
    end

    test "includes default data if form is untouched", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "contact: mail")
      |> assert_has("#form-data", text: "full_form_button: save")
    end

    test "can click button that does not submit form after filling form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "some@example.com")
      |> click_button("Save Nested Form")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test "submits owner form if button isn't nested inside form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#owner-form", fn session ->
        fill_in(session, "Name", with: "Aragorn")
      end)
      |> click_button("Save Owner Form")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("#redirect-form-submit", "Save Redirect Form")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form-to-static", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("#redirect-form-to-static-submit", "Save Redirect to Static")
      |> assert_has("h1", text: "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#non-liveview-form", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("Submit Non LiveView")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected form with selector "#invalid-form" to have a `phx-submit` or `action` defined.
        """)

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> within("#non-liveview-form", &fill_in(&1, "Name", with: "Aragorn"))
        |> click_button("Submit Invalid Form")
      end
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
        |> within("#no-phx-change-form", fn session ->
          session
          |> fill_in("Name", with: "Legolas")
          |> click_button("No button")
        end)
      end
    end
  end

  describe "within/3" do
    test "scopes assertions within selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("button", text: "Reset")
      |> within("#email-form", fn session ->
        refute_has(session, "button", text: "Reset")
      end)
    end

    test "scopes further form actions within a selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#email-form", fn session ->
        fill_in(session, "Email", with: "someone@example.com")
      end)
      |> assert_has(input(label: "Email", value: "someone@example.com"))
    end

    test "raises when data is not in scoped HTML", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with label "User Name"/, fn ->
        conn
        |> visit("/live/index")
        |> within("#email-form", fn session ->
          fill_in(session, "User Name", with: "Aragorn")
        end)
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

    test "can fill input with `nil` to override existing value", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#pre-rendered-data-form", fn session ->
        fill_in(session, "Pre Rendered Input", with: nil)
      end)
      |> assert_has("#form-data", text: "input's value is empty")
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
      |> assert_has("#form-data", text: "user:payer: off")
      |> assert_has("#form-data", text: "user:role: El Jefe")
    end

    test "triggers phx-change validations", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: nil)
      |> assert_has("#form-errors", text: "Errors present")
    end

    test "does not trigger phx-change event if one isn't present", %{conn: conn} do
      session = visit(conn, "/live/index")

      starting_html = Driver.render_html(session)

      ending_html =
        session
        |> within("#no-phx-change-form", &fill_in(&1, "Name", with: "Aragorn"))
        |> Driver.render_html()

      assert starting_html == ending_html
    end

    test "follows redirects on phx-change", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email with redirect", with: "someone@example.com")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "can be used to submit form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "someone@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test "can be combined with other forms' fill_ins (without pollution)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Country", with: "Bolivia")
      |> fill_in("City", with: "La Paz")
      |> assert_has("#form-data", text: "Bolivia: La Paz")
    end

    test "raises an error when element can't be found with label", %{conn: conn} do
      msg = ~r/Could not find element with label "Non-existent Email Label"./

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_in("Non-existent Email Label", with: "some@example.com")
      end
    end

    test "raises an error when label is found but no corresponding input is found", %{conn: conn} do
      msg = ~r/Found label but could not find corresponding element with matching `id`./

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_in("Email (no input)", with: "some@example.com")
      end
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

    test "works for multiple select", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> select(["Elf", "Dwarf"], from: "Race 2")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "[elf, dwarf]")
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

    test "can check an unchecked checkbox", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> uncheck("Admin")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end

    test "handle checkbox name with '?'", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Subscribe")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "subscribe?: on")
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Payer")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:payer: on")
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

    test "can uncheck a previous check/2 in the test", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Admin")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end

    test "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Payer")
      |> uncheck("Payer")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:payer: off")
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
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: mail")
    end
  end

  describe "filling out full form with field functions" do
    test "populates all fields", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Legolas")
      |> fill_in("Date", with: "2023-12-30")
      |> check("Admin")
      |> select("Elf", from: "Race")
      |> choose("Email Choice")
      |> fill_in("Notes", with: "Woodland Elf")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "name: Legolas")
      |> assert_has("#form-data", text: "date: 2023-12-30")
      |> assert_has("#form-data", text: "admin: on")
      |> assert_has("#form-data", text: "race: elf")
      |> assert_has("#form-data", text: "contact: email")
      |> assert_has("#form-data", text: "notes: Woodland Elf")
    end

    test "populates all fields in nested forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("User Name", with: "Legolas")
      |> select("True", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Legolas")
      |> assert_has("#form-data", text: "user:admin: true")
    end
  end

  describe "submit/1" do
    test "submits a pre-filled form via phx-submit", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "some@example.com")
      |> submit()
      |> assert_has("#form-data", text: "email: some@example.com")
    end

    test "includes pre-rendered data", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "race: human")
      |> assert_has("#form-data", text: "contact: mail")
    end

    test "includes the first button's name and value if present", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "full_form_button: save")
    end

    test "can submit form without button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Country of Origin", with: "Arnor")
      |> submit()
      |> assert_has("#form-data", text: "country: Arnor")
    end

    test "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "LiveView page 2")
    end

    test "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form-to-static", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "Main page")
    end

    test "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#non-liveview-form", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data", text: "button: save")
    end

    test "raises an error if there's no active form", %{conn: conn} do
      message = ~r/There's no active form. Fill in a form with `fill_in`, `select`, etc./

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/live/index")
        |> submit()
      end
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg =
        ignore_whitespace("""
        Expected form with selector "#invalid-form" to have a `phx-submit` or `action` defined.
        """)

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> within("#invalid-form", fn session ->
          session
          |> fill_in("Name", with: "Aragorn")
          |> submit()
        end)
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

  describe "unwrap" do
    test "provides an escape hatch that gives access to the underlying view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> unwrap(fn view ->
        view
        |> Phoenix.LiveViewTest.element("#hook")
        |> Phoenix.LiveViewTest.render_hook(:hook_event, %{name: "Legolas"})
      end)
      |> assert_has("#form-data", text: "name: Legolas")
    end

    test "follows redirects after unwrap action", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> unwrap(fn view ->
        view
        |> Phoenix.LiveViewTest.element("#hook-with-redirect")
        |> Phoenix.LiveViewTest.render_hook(:hook_with_redirect_event)
      end)
      |> assert_has("h1", text: "LiveView page 2")
    end
  end

  describe "session.current_path" do
    test "it is set on visit", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert session.current_path == "/live/index"
    end

    test "it is set on visit with query string", %{conn: conn} do
      session = visit(conn, "/live/index?foo=bar")

      assert session.current_path == "/live/index?foo=bar"
    end

    test "it is updated on href navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Navigate to non-liveview")

      assert session.current_path == "/page/index?details=true&foo=bar"
    end

    test "it is updated on live navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Navigate link")

      assert session.current_path == "/live/page_2?details=true&foo=bar"
    end

    test "it is updated on live patching", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Patch link")

      assert session.current_path == "/live/index?details=true&foo=bar"
    end

    test "it is updated on push navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_button("Button with push navigation")

      assert session.current_path == "/live/page_2?foo=bar"
    end

    test "it is updated on push patch", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_button("Button with push patch")

      assert session.current_path == "/live/index?foo=bar"
    end
  end
end
