defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Locators
  import PhoenixTest.TestHelpers

  alias PhoenixTest.Driver

  require PhoenixTest.TestHelpers

  setup context do
    conn = Phoenix.ConnTest.build_conn()
    conn = if context[:js], do: with_js_driver(conn), else: conn
    %{conn: conn}
  end

  describe "render_page_title/1" do
    test_also_with_js "renders the page title", %{conn: conn} do
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

    test_also_with_js "returns nil if page title isn't found", %{conn: conn} do
      title =
        conn
        |> visit("/live/index_no_layout")
        |> PhoenixTest.Driver.render_page_title()

      assert title == nil
    end
  end

  describe "visit/2" do
    test_also_with_js "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
    end

    test_also_with_js "follows redirects", %{conn: conn} do
      conn
      |> visit("/live/redirect_on_mount/redirect")
      |> assert_has("h1", text: "LiveView main page")
    end

    test_also_with_js "follows push redirects (push navigate)", %{conn: conn} do
      conn
      |> visit("/live/redirect_on_mount/push_navigate")
      |> assert_has("h1", text: "LiveView main page")
    end

    test "preserves headers across redirects", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/live/redirect_on_mount/redirect")
      |> assert_has("h1", text: "LiveView main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test "raises error if route doesn't exist", %{conn: conn} do
      assert_raise ArgumentError, ~r/404/, fn ->
        visit(conn, "/live/non_route")
      end
    end
  end

  describe "click_link/2" do
    test_also_with_js "follows 'navigate' links", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test_also_with_js "follows navigation that subsequently redirect", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate (and redirect back) link")
      |> assert_has("h1", text: "LiveView main page")
    end

    test_also_with_js "accepts click_link with selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("a", "Navigate link")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test_also_with_js "handles patches to current view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Patch link")
      |> assert_has("h2", text: "LiveView main page details")
    end

    test_also_with_js "handles navigation to a non-liveview", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_has("h1", text: "Main page")
    end

    test "preserves headers across navigation", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_has("h1", text: "Main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test_also_with_js "raises error when there are multiple links with same text", %{conn: conn} do
      # TODO Improve error matching
      assert_raise ArgumentError, fn ->
        conn
        |> visit("/live/index")
        |> click_link("Multiple links")
      end
    end

    test_also_with_js "raises an error when link element can't be found with given text", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> visit("/live/index")
        |> click_link("No link")
      end
    end

    test_also_with_js "raises an error when there are no links on the page", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> visit("/live/page_2")
        |> click_link("No link")
      end
    end
  end

  describe "click_button/2" do
    test_also_with_js "handles a `phx-click` button", %{conn: conn} do
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

    test_also_with_js "includes name and value if specified", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:no-phx-change-form-button: save")
    end

    test_also_with_js "includes default data if form is untouched", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "contact: mail")
      |> assert_has("#form-data", text: "level: 7")
      |> assert_has("#form-data", text: "full_form_button: save")
      |> assert_has("#form-data", text: "notes: Prefilled notes")
      |> refute_has("#form-data", text: "disabled_textarea:")
    end

    test_also_with_js "can click button that does not submit form after filling form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "some@example.com")
      |> click_button("Save Nested Form")
      |> refute_has("#form-data", text: "email: some@example.com")
    end

    test_also_with_js "submits owner form if button isn't nested inside form (including button data)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#owner-form", fn session ->
        fill_in(session, "Name", with: "Aragorn")
      end)
      |> click_button("Save Owner Form")
      |> assert_has("#form-data", text: "name: Aragorn")
      |> assert_has("#form-data", text: "form-button: save-owner-form")
    end

    test_also_with_js "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("#redirect-form-submit", "Save Redirect Form")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test_also_with_js "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form-to-static", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("#redirect-form-to-static-submit", "Save Redirect to Static")
      |> assert_has("h1", text: "Main page")
    end

    test_also_with_js "submits regular (non phx-submit) form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#non-liveview-form", &fill_in(&1, "Name", with: "Aragorn"))
      |> click_button("Submit Non LiveView")
      |> assert_has("#form-data", text: "name: Aragorn")
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg = ~r/to have a `phx-submit` or `action` defined/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> within("#non-liveview-form", &fill_in(&1, "Name", with: "Aragorn"))
        |> click_button("Submit Invalid Form")
      end
    end

    test_also_with_js "raises an error when there are no buttons on page", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find an element/, fn ->
        conn
        |> visit("/live/page_2")
        |> click_button("Show tab")
      end
    end

    test "raises an error if button is not part of form and has no phx-submit", %{conn: conn} do
      msg = ~r/to have a `phx-click` attribute or belong to a `form` element/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> click_button("Actionless Button")
      end
    end

    test_also_with_js "raises an error if active form but can't find button", %{conn: conn} do
      msg = ~r/Could not find an element/

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
    test_also_with_js "scopes assertions within selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("button", text: "Reset")
      |> within("#email-form", fn session ->
        refute_has(session, "button", text: "Reset")
      end)
    end

    test_also_with_js "scopes further form actions within a selector", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#email-form", fn session ->
        fill_in(session, "Email", with: "someone@example.com")
      end)
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test_also_with_js "raises when data is not in scoped HTML", %{conn: conn} do
      assert_raise ArgumentError, ~r/Could not find element with label "User Name"/, fn ->
        conn
        |> visit("/live/index")
        |> within("#email-form", fn session ->
          fill_in(session, "User Name", with: "Aragorn")
        end)
      end
    end
  end

  describe "fill_in/4" do
    # JS: Browser does not update `input.value` attribute when filling in field
    test "fills in a single text field based on the label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "someone@example.com")
      |> assert_has(input(label: "Email", value: "someone@example.com"))
    end

    test_also_with_js "can fill input with `nil` to override existing value", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#pre-rendered-data-form", fn session ->
        fill_in(session, "Pre Rendered Input", with: nil)
      end)
      |> assert_has("#form-data", text: "input's value is empty")
    end

    test_also_with_js "can fill-in textareas", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Notes", with: "Dunedain. Heir to the throne. King of Arnor and Gondor")
      |> click_button("Save Full Form")
      |> assert_has("#form-data",
        text: "notes: Dunedain. Heir to the throne. King of Arnor and Gondor"
      )
    end

    test_also_with_js "can fill-in complex form fields", %{conn: conn} do
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

    test_also_with_js "can fill in numbers", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Level (number)", with: 10)
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "level: 10")
    end

    test_also_with_js "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("User Name", with: "Aragorn")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:name: Aragorn")
      |> assert_has("#form-data", text: "user:payer: off")
      |> assert_has("#form-data", text: "user:role: El Jefe")
    end

    test_also_with_js "can be used to submit form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "someone@example.com")
      |> click_button("Save Email")
      |> assert_has("#form-data", text: "email: someone@example.com")
    end

    test_also_with_js "can be combined with other forms' fill_ins (without pollution)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "frodo@example.com")
      |> fill_in("Comments", with: "Hobbit")
      |> assert_has("#form-data", text: "comments: Hobbit")
      |> refute_has("#form-data", text: "email: frodo@example.com")
    end

    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        fill_in(session, "Name", with: "Frodo", exact: false)
      end)
      |> assert_has("#form-data", text: "name: Frodo")
    end

    test_also_with_js "can target input with selector if multiple labels have same text", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        fill_in(session, "#book-characters", "Character", with: "Frodo")
      end)
      |> assert_has("#form-data", text: "book-characters: Frodo")
    end

    test_also_with_js "raises an error when element can't be found with label", %{conn: conn} do
      msg = ~r/Could not find element with label "Non-existent Email Label"./

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_in("Non-existent Email Label", with: "some@example.com")
      end
    end

    test_also_with_js "raises an error when label is found but no corresponding input is found", %{conn: conn} do
      msg = ~r/Found label but can't find labeled element whose `id` matches/

      assert_raise ArgumentError, msg, fn ->
        conn
        |> visit("/live/index")
        |> fill_in("Email (no input)", with: "some@example.com")
      end
    end
  end

  describe "select/3" do
    test_also_with_js "selects given option for a label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> assert_has("#full-form option[value='elf']")
    end

    test_also_with_js "allows selecting option if a similar option exists", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Orc", from: "Race")
      |> assert_has("#full-form option[value='orc']")
    end

    test_also_with_js "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("False", from: "User Admin")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:admin: false")
    end

    test_also_with_js "can be used to submit form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "race: elf")
    end

    test_also_with_js "handles multi select", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select("Elf", from: "Race")
      |> select(["Elf", "Dwarf"], from: "Race 2")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "[elf, dwarf]")
    end

    test_also_with_js "works with phx-click outside of forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#not-a-form", fn session ->
        select(session, "Dog", from: "Choose a pet:")
      end)
      |> assert_has("#form-data", text: "selected: [dog]")
    end

    test_also_with_js "works with phx-click and multi-select", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#not-a-form", fn session ->
        select(session, ["Dog", "Cat"], from: "Choose a pet:")
      end)
      |> assert_has("#form-data", text: "selected: [dog, cat]")
    end

    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        select(session, "Cat", from: "Choose a pet:", exact: false)
      end)
      |> assert_has("#form-data", text: "pet: cat")
    end

    test_also_with_js "can target an option's text with exact_option: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#full-form", fn session ->
        select(session, "Dwa", from: "Race", exact_option: false)
      end)
      |> submit()
      |> assert_has("#form-data", text: "race: dwarf")
    end

    test_also_with_js "can target option with selector if multiple labels have same text", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        select(session, "#select-favorite-character", "Sam", from: "Character")
      end)
      |> assert_has("#form-data", text: "favorite-character: Frodo")
    end

    test "raises an error if select option is neither in a form nor has a phx-click", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/to have a `phx-click` attribute on options or to belong to a `form`/, fn ->
        select(session, "Dog", from: "Invalid Select Option")
      end
    end

    test_also_with_js "second call preserves values of first call for multi select (union)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> select(["Human", "Elf"], from: "Race 2")
      |> select(["Dwarf", "Orc"], from: "Race 2")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "[human, elf, dwarf, orc]")
    end
  end

  describe "check/3" do
    @tag :fix
    test_also_with_js "checks a checkbox", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end

    test_also_with_js "can check an unchecked checkbox", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> uncheck("Admin")
      |> check("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: on")
    end

    test_also_with_js "handle checkbox name with '?'", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Subscribe")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "subscribe?: on")
    end

    test_also_with_js "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Payer")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:payer: on")
    end

    test_also_with_js "works with phx-click outside a form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#not-a-form", fn session ->
        check(session, "Second Breakfast")
      end)
      |> assert_has("#form-data", text: "value: second-breakfast")
    end

    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        check(session, "Human", exact: false)
      end)
      |> assert_has("#form-data", text: "human: yes")
    end

    test_also_with_js "can specify input selector when multiple checkboxes have same label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        check(session, "#like-elixir", "Yes")
      end)
      |> assert_has("#form-data", text: "like-elixir: yes")
    end

    test "raises error if checkbox doesn't have phx-click or belong to form", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/have a `phx-click` attribute or belong to a `form`/, fn ->
        check(session, "Invalid Checkbox")
      end
    end
  end

  describe "uncheck/3" do
    test_also_with_js "sends the default value (in hidden input)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end

    test_also_with_js "can uncheck a previous check/2 in the test", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Admin")
      |> uncheck("Admin")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "admin: off")
    end

    test_also_with_js "works in 'nested' forms", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> check("Payer")
      |> uncheck("Payer")
      |> click_button("Save Nested Form")
      |> assert_has("#form-data", text: "user:payer: off")
    end

    test_also_with_js "works with phx-click outside a form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#not-a-form", fn session ->
        session
        |> check("Second Breakfast")
        |> uncheck("Second Breakfast")
      end)
      |> refute_has("#form-data", text: "value: second-breakfast")
    end

    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        session
        |> check("Human", exact: false)
        |> uncheck("Human", exact: false)
      end)
      |> assert_has("#form-data", text: "human: no")
    end

    test_also_with_js "can specify input selector when multiple checkboxes have same label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        session
        |> check("#like-elixir", "Yes")
        |> uncheck("#like-elixir", "Yes")
      end)
      |> refute_has("#form-data", text: "like-elixir: yes")
      |> assert_has("#form-data", text: "like-elixir: no")
    end

    test "raises error if checkbox doesn't have phx-click or belong to form", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/have a `phx-click` attribute or belong to a `form`/, fn ->
        uncheck(session, "Invalid Checkbox")
      end
    end
  end

  describe "choose/3" do
    test_also_with_js "chooses an option in radio button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> choose("Email Choice")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: email")
    end

    test_also_with_js "uses the default 'checked' if present", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Save Full Form")
      |> assert_has("#form-data", text: "contact: mail")
    end

    test_also_with_js "works with a phx-click outside of a form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#not-a-form", fn session ->
        choose(session, "Huey")
      end)
      |> assert_has("#form-data", text: "value: huey")
    end

    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        choose(session, "Book", exact: false)
      end)
      |> assert_has("#form-data", text: "book-or-movie: book")
    end

    test_also_with_js "can specify input selector when multiple options have same label in same form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        choose(session, "#elixir-yes", "Yes")
      end)
      |> assert_has("#form-data", text: "elixir-yes: yes")
    end

    test "raises an error if radio is neither in a form nor has a phx-click", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/to have a `phx-click` attribute or belong to a `form` element/, fn ->
        choose(session, "Invalid Radio Button")
      end
    end
  end

  describe "upload/4" do
    test_also_with_js "uploads an image", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#full-form", fn session ->
        session
        |> upload("Avatar", "test/files/elixir.jpg")
        |> click_button("Save Full Form")
      end)
      |> assert_has("#form-data", text: "avatar: elixir.jpg")
    end

    @tag :fix
    test_also_with_js "can target a label with exact: false", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#complex-labels", fn session ->
        session
        |> upload("Avatar", "test/files/elixir.jpg", exact: false)
        |> click_button("Save")
      end)
      |> assert_has("#form-data", text: "complex_avatar: elixir.jpg")
    end

    @tag :fix
    test_also_with_js "can specify input selector when multiple inputs have same label", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#same-labels", fn session ->
        session
        |> upload("[name='main_avatar']", "Avatar", "test/files/elixir.jpg")
        |> click_button("Submit Form")
      end)
      |> assert_has("#form-data", text: "main_avatar: elixir.jpg")
    end

    @tag :fix
    test "upload (without other form actions) does not work with submit (matches browser behavior)",
         %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> within("#full-form", fn session ->
          upload(session, "Avatar", "test/files/elixir.jpg")
        end)

      assert_raise ArgumentError, ~r/no active form/, fn ->
        submit(session)
      end
    end
  end

  describe "filling out full form with field functions" do
    test_also_with_js "populates all fields", %{conn: conn} do
      conn
      |> visit("/live/index")
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

    test_also_with_js "populates all fields in nested forms", %{conn: conn} do
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
    test_also_with_js "submits a pre-filled form via phx-submit", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "some@example.com")
      |> submit()
      |> assert_has("#form-data", text: "email: some@example.com")
    end

    test_also_with_js "includes pre-rendered data", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "admin: off")
      |> assert_has("#form-data", text: "race: human")
      |> assert_has("#form-data", text: "contact: mail")
    end

    test_also_with_js "includes the first button's name and value if present", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("First Name", with: "Aragorn")
      |> submit()
      |> assert_has("#form-data", text: "full_form_button: save")
    end

    test_also_with_js "can submit form without button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Country of Origin", with: "Arnor")
      |> submit()
      |> assert_has("#form-data", text: "country: Arnor")
    end

    test_also_with_js "follows form's redirect to live page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "LiveView page 2")
    end

    test_also_with_js "follows form's redirect to static page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#redirect-form-to-static", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "Main page")
    end

    test "preserves headers after form submission and redirect", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
      |> visit("/live/index")
      |> within("#redirect-form-to-static", fn session ->
        session
        |> fill_in("Name", with: "Aragorn")
        |> submit()
      end)
      |> assert_has("h1", text: "Main page")
      |> then(fn %{conn: conn} ->
        assert {"x-custom-header", "Some-Value"} in conn.req_headers
      end)
    end

    test_also_with_js "submits regular (non phx-submit) form", %{conn: conn} do
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

    test_also_with_js "raises an error if there's no active form", %{conn: conn} do
      message = ~r/There's no active form. Fill in a form with `fill_in`, `select`, etc./

      assert_raise ArgumentError, message, fn ->
        conn
        |> visit("/live/index")
        |> submit()
      end
    end

    test "raises an error if form doesn't have a `phx-submit` or `action`", %{conn: conn} do
      msg = ~r/to have a `phx-submit` or `action` defined/

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

  describe "current_path" do
    test "it is set on visit", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert PhoenixTest.Driver.current_path(session) == "/live/index"
    end

    test "it is set on visit with query string", %{conn: conn} do
      session = visit(conn, "/live/index?foo=bar")

      assert PhoenixTest.Driver.current_path(session) == "/live/index?foo=bar"
    end

    test "it is updated on href navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Navigate to non-liveview")

      assert PhoenixTest.Driver.current_path(session) == "/page/index?details=true&foo=bar"
    end

    test "it is updated on live navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Navigate link")

      assert PhoenixTest.Driver.current_path(session) == "/live/page_2?details=true&foo=bar"
    end

    test "it is updated on live patching", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_link("Patch link")

      assert PhoenixTest.Driver.current_path(session) == "/live/index?details=true&foo=bar"
    end

    test "it is updated on push navigation", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_button("Button with push navigation")

      assert PhoenixTest.Driver.current_path(session) == "/live/page_2?foo=bar"
    end

    test "it is updated on push patch", %{conn: conn} do
      session =
        conn
        |> visit("/live/index")
        |> click_button("Button with push patch")

      assert PhoenixTest.Driver.current_path(session) == "/live/index?foo=bar"
    end
  end

  describe "shared form helpers behavior" do
    test_also_with_js "triggers phx-change validations", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "email")
      |> fill_in("Email", with: nil)
      |> assert_has("#form-errors", text: "Errors present")
    end

    test_also_with_js "sends _target with phx-change events", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email", with: "frodo@example.com")
      |> assert_has("#form-data", text: "_target: [email]")
    end

    test_also_with_js "does not trigger phx-change event if one isn't present", %{conn: conn} do
      session = visit(conn, "/live/index")

      starting_html = Driver.render_html(session)

      ending_html =
        session
        |> within("#no-phx-change-form", &fill_in(&1, "Name", with: "Aragorn"))
        |> Driver.render_html()

      assert starting_html == ending_html
    end

    test_also_with_js "follows redirects on phx-change", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_in("Email with redirect", with: "someone@example.com")
      |> assert_has("h1", text: "LiveView page 2")
    end

    test_also_with_js "preserves correct order of active form vs form data", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> within("#changes-hidden-input-form", fn session ->
        session
        |> fill_in("Name", with: "Frodo")
        |> fill_in("Email", with: "frodo@example.com")
      end)
      |> assert_has("#form-data", text: "name: Frodo")
      |> assert_has("#form-data", text: "email: frodo@example.com")
      |> assert_has("#form-data", text: "hidden_race: hobbit")
    end
  end
end
