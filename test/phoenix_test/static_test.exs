defmodule PhoenixTest.StaticTest do
  use ExUnit.Case, async: true
  use PhoenixTest.Case, playwright: :chromium

  import PhoenixTest
  import PhoenixTest.TestHelpers

  describe "render_page_title/1" do
    test_also_with_playwright "renders the page title", %{conn: conn} do
      title =
        conn
        |> visit("/page/index")
        |> PhoenixTest.Driver.render_page_title()

      assert title == "PhoenixTest is the best!"
    end

    # TODO Playwright "" vs nil
    test "renders nil if there's no page title", %{conn: conn} do
      title =
        conn
        |> visit("/page/index_no_layout")
        |> PhoenixTest.Driver.render_page_title()

      assert title == nil
    end
  end

  describe "visit/2" do
    test_also_with_playwright "navigates to given static page", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
    end

    test_also_with_playwright "follows redirects", %{conn: conn} do
      conn
      |> visit("/page/redirect_to_static")
      |> assert_has("h1", text: "Main page")
    end

    test "preserves headers across redirects", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/page/redirect_to_static")
      |> assert_has("h1", text: "Main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test "raises error if route doesn't exist", %{conn: conn} do
      assert_raise ArgumentError, ~r/404/, fn ->
        visit(conn, "/non_route")
      end
    end
  end

  describe "click_link/2" do
    test_also_with_playwright "follows link's path", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Page 2")
      |> assert_has("h1", text: "Page 2")
    end

    test_also_with_playwright "follows link that subsequently redirects", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Navigate away and redirect back")
      |> assert_has("h1", text: "Main page")
    end

    test_also_with_playwright "accepts selector for link", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("a", "Page 2")
      |> assert_has("h1", text: "Page 2")
    end

    test "preserves headers across navigation", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/page/index")
      |> click_link("a", "Page 2")
      |> assert_has("h1", text: "Page 2")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test_also_with_playwright "handles navigation to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("To LiveView!")
      |> assert_has("h1", text: "LiveView main page")
    end

    test_also_with_playwright "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_link("Data_method Delete")
      |> assert_has("h1", text: "Record deleted")
    end

    test "raises error if trying to submit via `data-` attributes but incomplete", %{conn: conn} do
      msg =
        ignore_whitespace("""
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
        """)

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_link("Incomplete data-method Delete")
      end
    end

    test_also_with_playwright "raises error when there are multiple links with same text", %{conn: conn} do
      assert_raise ArgumentError, ~r/Found more than one element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_link("Multiple links")
      end
    end

    test_also_with_playwright "raises an error when link element can't be found with given text", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/index")
        |> click_link("No link")
      end
    end

    test_also_with_playwright "raises an error when there are no links on the page", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        conn
        |> visit("/page/page_2")
        |> click_link("No link")
      end
    end
  end

  describe "click_button/2" do
    test_also_with_playwright "handles a button that defaults to GET", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Get record")
      |> assert_has("h1", text: "Record received")
    end

    test_also_with_playwright "accepts selector for button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("button", "Get record")
      |> assert_has("h1", text: "Record received")
    end

    test_also_with_playwright "handles a button clicks when button PUTs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Mark as active")
      |> assert_has("h1", text: "Record updated")
    end

    test_also_with_playwright "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", text: "Record deleted")
    end

    test_also_with_playwright "can submit forms with input type submit", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Email", with: "sample@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: sample@example.com")
    end

    test_also_with_playwright "can handle clicking button that does not submit form after filling a form", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Email", with: "some@example.com")
      |> click_button("Delete record")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test_also_with_playwright "submits owner form if button isn't nested inside form", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#owner-form", fn session ->
        fill_in(session, "Name", with: "Aragorn")
      end)
      |> click_button("Save Owner Form")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test_also_with_playwright "can handle redirects to a LiveView", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Post and Redirect")
      |> assert_has("h1", text: "LiveView main page")
    end

    test_also_with_playwright "handles form submission via `data-method` & `data-to` attributes", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Data_method Delete")
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

    test_also_with_playwright "includes name and value if specified", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:save-button: nested-form-save")
    end

    test_also_with_playwright "can handle clicking button that does not submit form after fill_in", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Email", with: "some@example.com")
      |> click_button("Delete record")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test_also_with_playwright "includes default data if form is untouched", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "contact: mail")
      |> assert_has("#form-data", text: "level: 7")
      |> assert_has("#form-data", text: "full_form_button: save")
      |> assert_has("#form-data", text: "notes: Prefilled notes")
      |> refute_has("#form-data", text: "disabled_textarea:")
    end

    test "raises error if trying to submit via `data-` attributes but incomplete", %{conn: conn} do
      msg = ~r/Tried submitting form via `data-method` but some data attributes/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_button("Incomplete data-method Delete")
      end
    end

    test_also_with_playwright "raises an error when there are no buttons on page", %{conn: conn} do
      msg = ~r/Could not find an element with given selectors/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/page_2")
        |> click_button("Show tab")
      end
    end

    test_also_with_playwright "raises an error if can't find button", %{conn: conn} do
      msg = ~r/Could not find an element with given selectors/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_button("No button")
      end
    end

    test "raises an error if button is not part of form", %{conn: conn} do
      msg =
        ~r/Could not find "form" for an element with selector/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> click_button("Actionless Button")
      end
    end
  end

  describe "within/3" do
    # TODO Playwright: Fix refute_has
    test "scopes assertions within selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("button", text: "Get record")
      |> within("#email-form", fn session ->
        refute_has(session, "button", text: "Get record")
      end)
    end

    test_also_with_playwright "scopes further form actions within a selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#email-form", fn session ->
        session
        |> fill_in("Email", with: "someone@example.com")
        |> click_button("Save Email")
      end)
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test_also_with_playwright "raises when data is not in scoped HTML", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with label "User Name"/, fn ->
        conn
        |> visit("/page/index")
        |> within("#email-form", fn session ->
          fill_in(session, "User Name", with: "Aragorn")
        end)
      end
    end
  end

  describe "fill_in/4" do
    test_also_with_playwright "fills in a single text field based on the label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Email", with: "someone@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test_also_with_playwright "can fill input with `nil` to override existing value", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Pre Rendered Input", with: nil)
      |> submit()
      |> assert_has("#form-data", text: "input's value is empty")
    end

    test_also_with_playwright "can fill-in complex form fields", %{conn: conn} do
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

    test_also_with_playwright "can fill in numbers", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Level (number)", with: 10)
      |> submit()
      |> assert_has("#form-data", text: "level: 10")
    end

    test_also_with_playwright "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
      |> assert_has("#form-data", text: "user:admin: true")
      |> assert_has("#form-data", text: "user:payer: off")
      |> assert_has("#form-data", text: "user:role: El Jefe")
    end

    test_also_with_playwright "can be combined with other forms' fill_ins (without pollution)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("First Name", with: "Aragorn")
      |> fill_in("User Name", with: "Legolas")
      |> submit()
      |> refute_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data", text: "user:name: Legolas")
    end

    test_also_with_playwright "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        fill_in(session, "Name", with: "Frodo", exact: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "name: Frodo")
    end

    test_also_with_playwright "can target input with selector if multiple labels have same text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        fill_in(session, "#book-characters", "Character", with: "Frodo")
      end)
      |> submit()
      |> assert_has("#form-data", text: "book-characters: Frodo")
    end

    test_also_with_playwright "raises an error when element can't be found with label", %{conn: conn} do
      msg = ~r/Could not find element with label "Non-existent Email Label"./

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> fill_in("Non-existent Email Label", with: "some@example.com")
      end
    end

    # TODO Playwright: Fix error message
    test "raises an error when label is found but no corresponding input is found", %{conn: conn} do
      msg = ~r/Found label but can't find labeled element whose `id` matches/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> fill_in("Email (no input)", with: "some@example.com")
      end
    end
  end

  describe "select/3" do
    test_also_with_playwright "selects given option for a label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select("Elf", from: "Race")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race: elf")
    end

    test_also_with_playwright "picks first by default", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race: human")
    end

    test_also_with_playwright "allows selecting option if a similar option exists", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select("Orc", from: "Race")
      |> assert_has("#full-form option[value='orc']")
    end

    test_also_with_playwright "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select("False", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:admin: false")
    end

    # TODO Playwright: Support selecting multiple
    test "handles multi select", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> select(["Elf", "Dwarf"], from: "Race 2")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race_2: [elf,dwarf]")
    end

    test_also_with_playwright "contains no data for empty multi select", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Save Full Form")
      |> refute_has("#form-data", text: "race_2")
    end

    # TODO Playwright: Support submit() when select is focused
    test "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        select(session, "Dog", from: "Choose a pet:", exact: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "pet: dog")
    end

    # TODO Playwright: Use strict=false
    test "can target an option's text with exact_option: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#full-form", fn session ->
        select(session, "Hum", from: "Race", exact_option: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "race: human")
    end

    # TODO Playwright: Support submit() when select is focused
    test "can target option with selector if multiple labels have same text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        select(session, "#select-favorite-character", "Frodo", from: "Character")
      end)
      |> submit()
      |> assert_has("#form-data", text: "favorite-character: Frodo")
    end
  end

  describe "check/3" do
    test_also_with_playwright "checks a checkbox", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Admin (boolean)")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin_boolean: true")
    end

    test_also_with_playwright "sets checkbox value as 'on' by default", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end

    test_also_with_playwright "can check an unchecked checkbox", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> uncheck("Admin")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end

    test_also_with_playwright "handle checkbox name with '?'", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Subscribe")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "subscribe?: on")
    end

    test_also_with_playwright "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        check(session, "Human", exact: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "human: yes")
    end

    test_also_with_playwright "can specify input selector when multiple checkboxes have same label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        check(session, "#like-elixir", "Yes")
      end)
      |> submit()
      |> assert_has("#form-data", text: "like-elixir: yes")
    end
  end

  describe "uncheck/3" do
    test_also_with_playwright "sends the default value (in hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end

    test_also_with_playwright "can uncheck a previous check/2 in the test", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> check("Admin")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end

    test_also_with_playwright "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        session
        |> check("Human", exact: false)
        |> uncheck("Human", exact: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "human: no")
    end

    test_also_with_playwright "can specify input selector when multiple checkboxes have same label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        session
        |> check("#like-elixir", "Yes")
        |> uncheck("#like-elixir", "Yes")
      end)
      |> submit()
      |> refute_has("#form-data", text: "like-elixir: yes")
      |> assert_has("#form-data", text: "like-elixir: no")
    end
  end

  describe "choose/3" do
    test_also_with_playwright "chooses an option in radio button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> choose("Email Choice")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: email")
    end

    test_also_with_playwright "uses the default 'checked' if present", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: mail")
    end

    test_also_with_playwright "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        choose(session, "Book", exact: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "book-or-movie: book")
    end

    test_also_with_playwright "can specify input selector when multiple options have same label in same form", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        session
        |> choose("#elixir-yes", "Yes")
        |> click_button("Save form")
      end)
      |> assert_has("#form-data", text: "elixir-yes: yes")
    end
  end

  describe "upload/4" do
    test_also_with_playwright "uploads image", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#file-upload-form", fn session ->
        session
        |> upload("Avatar", "test/files/elixir.jpg")
        |> click_button("Save File upload Form")
      end)
      |> assert_has("#form-data", text: "avatar: elixir.jpg")
    end

    # TODO Playwright: Support multiple subsequent upload calls for same field
    test "uploads image list", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> upload("Avatar list 0", "test/files/elixir.jpg")
      |> upload("Avatar list 1", "test/files/phoenix.jpg")
      |> click_button("Save File upload Form")
      |> assert_has("#form-data", text: "avatars:[]: elixir.jpg")
      |> assert_has("#form-data", text: "avatars:[]: phoenix.jpg")
    end

    test_also_with_playwright "uploads an image in nested forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> upload("Nested Avatar", "test/files/elixir.jpg")
      |> click_button("Save File upload Form")
      |> assert_has("#form-data", text: "user:avatar: elixir.jpg")
    end

    test_also_with_playwright "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#complex-labels", fn session ->
        session
        |> upload("Avatar", "test/files/elixir.jpg", exact: false)
        |> click_button("Save")
      end)
      |> assert_has("#form-data", text: "avatar: elixir.jpg")
    end

    # TODO Playwright: fix
    test "can specify input selector when multiple inputs have same label", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#same-labels", fn session ->
        upload(session, "#main-avatar", "Avatar", "test/files/elixir.jpg")
      end)
      |> submit()
      |> assert_has("#form-data", text: "main-avatar: elixir.jpg")
    end
  end

  describe "filling out full form with field functions" do
    test_also_with_playwright "populates all fields", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("First Name", with: "Legolas")
      |> fill_in("Date", with: Date.new!(2023, 12, 30))
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

    test_also_with_playwright "populates all fields in nested forms", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("User Name", with: "Legolas")
      |> select("True", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Legolas")
      |> assert_has("#form-data", text: "user:admin: true")
    end
  end

  describe "submit/1" do
    test_also_with_playwright "submits form even if no submit is present (acts as <Enter>)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#no-submit-button-form", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test_also_with_playwright "includes pre-rendered data (input value, selected option, checked checkbox, checked radio button)",
                              %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "race: human")
    end

    test_also_with_playwright "includes the first button's name and value if present", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "full_form_button: save")
    end

    test_also_with_playwright "can submit form without button", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> fill_in("Country of Origin", with: "Arnor")
      |> submit()
      |> assert_has("#form-data", text: "country: Arnor")
    end

    test_also_with_playwright "can handle redirects", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#no-submit-button-and-redirect", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "LiveView main page")
    end

    test "preserves headers after form submission and redirect", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/page/index")
      |> within("#no-submit-button-and-redirect", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "LiveView main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test_also_with_playwright "handles when form PUTs data through hidden input", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> within("#update-form", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test_also_with_playwright "handles a button clicks when button DELETEs data (hidden input)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> click_button("Delete record")
      |> assert_has("h1", text: "Record deleted")
    end

    test "raises an error if there's no active form", %{conn: conn} do
      msg = ~r/There's no active form. Fill in a form with `fill_in`, `select`, etc./

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/page/index")
        |> submit()
      end
    end
  end

  describe "open_browser" do
    setup do
      open_fun = fn path ->
        assert content = File.read!(path)

        assert content =~
                 ~r[<link rel="stylesheet" href="file:.*phoenix_test\/priv\/static\/assets\/app\.css"\/>]

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

    test_also_with_playwright "opens the browser ", %{conn: conn, open_fun: open_fun} do
      conn
      |> visit("/page/index")
      |> open_browser(open_fun)
      |> assert_has("h1", text: "Main page")
    end
  end

  describe "unwrap" do
    require Phoenix.ConnTest

    @endpoint Application.compile_env(:phoenix_test, :endpoint)

    test "provides an escape hatch that gives access to the underlying conn", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> unwrap(fn conn ->
        Phoenix.ConnTest.put_flash(conn, :info, "hello")
      end)
      |> then(fn %{conn: conn} ->
        assert conn.assigns.flash == %{"info" => "hello"}
      end)
    end

    test "follows redirects after unwrap action", %{conn: conn} do
      conn
      |> visit("/page/page_2")
      |> unwrap(fn conn ->
        Phoenix.ConnTest.post(conn, "/page/redirect_to_static", %{})
      end)
      |> assert_has("h1", text: "Main page")
    end
  end

  describe "current_path" do
    test_also_with_playwright "it is set on visit", %{conn: conn} do
      session = visit(conn, "/page/index")

      assert PhoenixTest.Driver.current_path(session) == "/page/index"
    end

    test_also_with_playwright "it includes query string if available", %{conn: conn} do
      session = visit(conn, "/page/index?foo=bar")

      assert PhoenixTest.Driver.current_path(session) == "/page/index?foo=bar"
    end

    # TODO Playwright: Fix (maybe not possible, because need to await navigation)
    test "it is updated on href navigation", %{conn: conn} do
      session =
        conn
        |> visit("/page/index")
        |> click_link("Page 2")

      assert PhoenixTest.Driver.current_path(session) == "/page/page_2?foo=bar"
    end

    test_also_with_playwright "it is updated on redirects", %{conn: conn} do
      session =
        conn
        |> visit("/page/index")
        |> click_link("Navigate away and redirect back")

      assert PhoenixTest.Driver.current_path(session) == "/page/index"
    end
  end
end
