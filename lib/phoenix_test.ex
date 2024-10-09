defmodule PhoenixTest do
  @moduledoc """
  PhoenixTest provides a unified way of writing feature tests -- regardless of
  whether you're testing LiveView pages or static pages.

  It also handles navigation between LiveView and static pages seamlessly. So, you
  don't have to worry about what type of page you're visiting. Just write the
  tests from the user's perspective.

  Thus, you can test a flow going from static to LiveView pages and back without
  having to worry about the underlying implementation.

  This is a sample flow:

  ```elixir
  test "admin can create a user", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Users")
    |> fill_in("Name", with: "Aragorn")
    |> choose("Ranger")
    |> assert_has(".user", text: "Aragorn")
  end
  ```

  Note that PhoenixTest does _not_ handle JavaScript. If you're looking for
  something that supports JavaScript, take a look at
  [Wallaby](https://hexdocs.pm/wallaby/readme.html).

  ## Setup

  PhoenixTest requires Phoenix `1.7+` and LiveView `0.20+`. It may work with
  earlier versions, but I have not tested that.

  ### Installation

  Add `phoenix_test` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:phoenix_test, "~> 0.4.0", only: :test, runtime: false}
    ]
  end
  ```

  ### Configuration

  In `config/test.exs` specify the endpoint to be used for routing requests:

  ```elixir
  config :phoenix_test, :endpoint, MyAppWeb.Endpoint
  ```

  ### Getting `PhoenixTest` helpers

  `PhoenixTest` helpers can be included via `import PhoenixTest`.

  But since each test needs a `conn` struct to get started, you'll likely want
  to set up a few things before that.

  There are two ways to do that.

  ### With `ConnCase`

  If you plan to use `ConnCase` solely for `PhoenixTest`, then you can import
  the helpers there:

  ```elixir
  using do
    quote do
      # importing other things for ConnCase

      import PhoenixTest

      # doing other setup for ConnCase
    end
  end
  ```

  ### Adding a `FeatureCase`

  If you want to create your own `FeatureCase` helper module like `ConnCase`,
  you can copy the code below which can be `use`d from your tests (replace
  `MyApp` with your app's name):

  ```elixir
  defmodule MyAppWeb.FeatureCase do
    use ExUnit.CaseTemplate

    using do
      quote do
        use MyAppWeb, :verified_routes

        import MyAppWeb.FeatureCase

        import PhoenixTest
      end
    end

    setup tags do
      pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end
  end
  ```

  Note that we assume your Phoenix project is using Ecto and its phenomenal
  `SQL.Sandbox`. If it doesn't, feel free to remove the `SQL.Sandbox` code
  above.

  ## Usage

  Now that we have all the setup out of the way, we can create tests like
  this:

  ```elixir
  # test/my_app_web/features/admin_can_create_user_test.exs

  defmodule MyAppWeb.AdminCanCreateUserTest do
    use MyAppWeb.FeatureCase, async: true

    test "admin can create user", %{conn: conn} do
      conn
      |> visit("/")
      |> click_link("Users")
      |> fill_in("Name", with: "Aragorn")
      |> fill_in("Email", with: "aragorn@dunedain.com")
      |> click_button("Create")
      |> assert_has(".user", text: "Aragorn")
    end
  end
  ```

  ### Filling out forms

  We can fill out forms by targetting their inputs, selects, etc. by label:

  ```elixir
  test "admin can create user", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Users")
    |> fill_in("Name", with: "Aragorn")
    |> select("Elessar", from: "Aliases")
    |> choose("Human") # <- choose a radio option
    |> check("Ranger") # <- check a checkbox
    |> click_button("Create")
    |> assert_has(".user", text: "Aragorn")
  end
  ```

  For more info, see `fill_in/3`, `select/3`, `choose/3`, `check/2`,
  `uncheck/2`.

  ### Submitting forms without clicking a button

  Once we've filled out a form, you can click a button with
  `click_button/2` to submit the form. But sometimes you want to emulate what
  would happen by just pressing <Enter>.

  For that case, you can use `submit/1` to submit the form you just filled
  out.

  ```elixir
  session
  |> fill_in("Name", with: "Aragorn")
  |> check("Ranger")
  |> submit()
  ```

  For more info, see `submit/1`.

  ### Targeting which form to fill out

  If you find yourself in a situation where you have multiple forms with the
  same labels (even when those labels point to different inputs), then you
  might have to scope your form-filling.

  To do that, you can scope all of the form helpers using `within/3`:

  ```elixir
  session
  |> within("#user-form", fn session ->
    session
    |> fill_in("Name", with: "Aragorn")
    |> check("Ranger")
    |> click_button("Create")
  end)
  ```

  For more info, see `within/3`.
  """

  import Phoenix.ConnTest
  import PhoenixTest.Locators

  alias PhoenixTest.Button
  alias PhoenixTest.Driver
  alias PhoenixTest.Query

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  @doc """
  Entrypoint to create a session.

  `visit/2` takes a `Plug.Conn` struct and the path to visit.

  It returns a `session` which the rest of the `PhoenixTest` functions can use.

  Note that `visit/2` is smart enough to know if the page you're visiting is a
  LiveView or a static view. You don't need to worry about which type of page
  you're visiting.
  """
  if Code.ensure_loaded?(Playwright.Page) do
    def visit(%Playwright.Page{} = page, path) do
      PhoenixTest.Playwright.build(page, path)
    end
  end

  def visit(%Plug.Conn{} = conn, path) do
    conn
    |> recycle(all_headers(conn))
    |> get(path)
    |> case do
      %{assigns: %{live_module: _}} = conn ->
        PhoenixTest.Live.build(conn)

      %{status: 302} = conn ->
        path = redirected_to(conn)

        conn
        |> recycle(all_headers(conn))
        |> visit(path)

      conn ->
        PhoenixTest.Static.build(conn)
    end
  end

  defp all_headers(conn) do
    Enum.map(conn.req_headers, &elem(&1, 0))
  end

  @doc """
  Clicks a link with given text and performs the action.

  Here's how it handles different types of `a` tags:

  - With `href`: follows it to the next page
  - With `phx-click`: it'll send the event to the appropriate LiveView
  - With live redirect: it'll follow the live navigation to the next LiveView
  - With live patch: it'll patch the current LiveView

  ## Examples

  ```heex
  <.link href="/page/2">Page 2</.link>
  <.link phx-click="next-page">Next Page</.link>
  <.link navigate="next-liveview">Next LiveView</.link>
  <.link patch="page/details">Page Details</.link>
  ```

  ```elixir
  session
  |> click_link("Page 2") # <- follows to next page

  session
  |> click_link("Next Page") # <- sends "next-page" event to LiveView

  session
  |> click_link("Next LiveView") # <- follows to next LiveView

  session
  |> click_link("Page Details") # <- applies live patch
  ```

  ## Submitting forms

  Phoenix allows for submitting forms on links via Phoenix.HTML's `data-method`,
  `data-to`, and `data-csrf`.

  We can use `click_link` to emulate Phoenix.HTML.js and submit the
  form via data attributes.

  But note that this _doesn't guarantee_ the JavaScript that handles form
  submissions via `data` attributes is loaded. The test emulates the behavior
  but you must make sure the JavaScript is loaded.

  For more on that, see https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#module-javascript-library

  ### Example

  ```html
  <a href="/users/2" data-method="delete" data-to="/users/2" data-csrf="token">
    Delete
  </a>
  ```

  ```elixir
  session
  |> click_link("Delete") # <- will submit form like Phoenix.HTML.js does
  ```
  """
  def click_link(session, text) do
    click_link(session, "a", text)
  end

  @doc """
  Clicks a link with given CSS selector and text and performs the action.
  selector to target the link.

  See `click_link/2` for more details.
  """
  defdelegate click_link(session, selector, text), to: Driver

  @doc """
  Perfoms action defined by button (and based on attributes present).

  This can be used in a number of ways.

  ## Button with `phx-click`

  If the button has a `phx-click` on it, it'll send the event to the LiveView.

  ### Example

  ```html
  <button phx-click="save">Save</button>
  ```

  ```elixir
  session
  |> click_button("Save") # <- will send "save" event to LiveView
  ```

  ## Button relying on Phoenix.HTML.js

  If the button acts as a form via Phoenix.HTML's `data-method`, `data-to`, and
  `data-csrf`, this will emulate Phoenix.HTML.js and submit the form via data
  attributes.

  But note that this _doesn't guarantee_ the JavaScript that handles form
  submissions via `data` attributes is loaded. The test emulates the behavior
  but you must make sure the JavaScript is loaded.

  For more on that, see https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#module-javascript-library

  ### Example

  ```html
  <button data-method="delete" data-to="/users/2" data-csrf="token">Delete</button>
  ```

  ```elixir
  session
  |> click_button("Delete") # <- will submit form like Phoenix.HTML.js does
  ```

  ## Combined with `fill_in/3`, `select/3`, etc.

  This function can be preceded by filling out a form.

  ### Example

  ```elixir
  session
  |> fill_in("Name", name: "Aragorn")
  |> check("Human")
  |> click_button("Create")
  ```

  ### Submitting default data

  By default, using `click_button/2` will submit the form it's part of (so long
  as it has a `phx-click`, `data-*` attrs, or an `action`).

  It will also include any hidden inputs and default data (e.g. inputs with a
  `value` set and the button's `name` and `value` if present).

  ### Example

  ```html
  <form method="post" action="/users/2">
    <input type="hidden" name="admin" value="true"/>
    <button name="complete" value="true">Complete</button>
  </form>
  ```

  ```elixir
  session
  |> click_button("Complete")
  # ^ includes `%{"admin" => "true", "complete" => "true"}` in payload
  ```

  ## Single-button forms

  `click_button/2` is smart enough to use a hidden input's value with
  `name=_method` as the method to send (e.g. when we want to send `delete`,
  `put`, or `patch`)

  That means, it is helpful to submit single-button forms.

  ### Example

  ```html
  <form method="post" action="/users/2">
    <input type="hidden" name="_method" value="delete" />
    <button>Delete</button>
  </form>
  ```

  ```elixir
  session
  |> click_button("Delete") # <- Triggers full form delete.
  ```
  """

  def click_button(session, text) do
    click(session, button(text: text))
  end

  @doc """
  Performs action defined by button with CSS selector and text.

  See `click_button/2` for more details.
  """
  defdelegate click_button(session, selector, text), to: Driver

  defp click(session, {:button, _} = locator) do
    html = Driver.render_html(session)

    button =
      html
      |> Query.find_by_role!(locator)
      |> Button.build(html)

    Driver.click_button(session, button.selector, button.text)
  end

  @doc """
  Helpers to scope filling out form within a given selector. Use this if you
  have more than one form on a page with similar labels.

  ## Examples

  Given we have some HTML like this:

  ```html
  <form id="user-form" action="/users" method="post">
    <label for="name">Name</label>
    <input id="name" name="name"/>

    <input type="hidden" name="admin" value="off" />
    <label for="admin">Admin</label>
    <input id="admin" type="checkbox" name="admin" value="on" />
  </form>

  # and assume another form with "Name" and "Admin" labels
  ```

  We can fill the form like this:

  ```elixir
  session
  |> within("#user-form", fn session ->
    session
    |> fill_in("Name", with: "Aragorn")
    |> check("Admin")
  end)
  ```
  """
  defdelegate within(session, selector, fun), to: Driver

  @doc """
  Fills text inputs and textareas, targetting the elements by their labels.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `fill_in/3` will trigger the `phx-change` event.

  ## Options

  - `with` (required): the text to fill in.

  - `exact`: whether to match label text exactly. (Defaults to `true`)

  ## Examples

  Given we have a form that contains this:

  ```html
  <label for="name">Name</label>
  <input id="name" name="name"/>
  ```

  or this:

  ```html
  <label>
    Name
    <input name="name"/>
  </label>
  ```

  We can fill in the `name` field:

  ```elixir
  session
  |> fill_in("Name", with: "Aragorn")
  ```

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given the following:

  ```html
  <label for="name">Name <span>*</span></label>
  <input id="name" name="name"/>
  ```

  We can fill in the `name` field:

  ```elixir
  session
  |> fill_in("Name", with: "Aragorn", exact: false)
  ```
  """
  def fill_in(session, label, attrs) when is_binary(label) and is_list(attrs) do
    opts = Keyword.validate!(attrs, [:with, exact: true])
    fill_in(session, ["input:not([type='hidden'])", "textarea"], label, opts)
  end

  @doc """
  Like `fill_in/3` but you can specify an input's selector (in addition to the
  label).

  Helpful for cases when you have multiple fields with the same label.

  ## Example

  Consider a form containig the following:

  ```html
  <div>
    <div>
      <label for="contact_0_first_name">First Name</label>
      <input type="text" name="contact[0][first_name]" id="contact_0_first_name" />
    </div>
  </div>

  <div>
    <div>
      <label for="contact_1_first_name">First Name</label>
      <input type="text" name="contact[1][first_name]" id="contact_1_first_name" value="">
    </div>
  </div>
  ```

  Since each new contact gets the same "First Name" label, you can target a
  specific input like so:

  ```elixir
  session
  |> fill_in("#contact_1_first_name", with: "First Name")
  ```
  """
  def fill_in(session, input_selector, label, attrs) when is_binary(label) and is_list(attrs) do
    opts = Keyword.validate!(attrs, [:with, exact: true])
    Driver.fill_in(session, input_selector, label, opts)
  end

  @doc """
  Selects an option from a select dropdown.

  ## Options

  - `from` (required): the label of the select dropdown.

  - `exact`: whether to match label text exactly. (Defaults to `true`)

  - `exact_option`: whether to match the option's text exactly. (Defaults to `true`)

  ## Inside a form

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `select/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  ### Example

  Given we have a form that contains this:

  ```html
  <form>
    <label for="race">Race</label>
    <select id="race" name="race">
      <option value="human">Human</option>
      <option value="elf">Elf</option>
      <option value="dwarf">Dwarf</option>
      <option value="orc">Orc</option>
    </select>
  </form>
  ```

  We can select an option:

  ```elixir
  session
  |> select("Human", from: "Race")
  ```

  ## Outside a form

  If the select dropdown exists outside of a form, `select/3` will trigger the
  `phx-click` event associated to the option being selected (note that all
  options must have a `phx-click` in that case).

  ### Examples

  Given we have a form that contains this:

  ```html
  <label for="race">Race</label>
  <select id="race" name="race">
    <option phx-click="select-race" value="human">Human</option>
    <option phx-click="select-race" value="elf">Elf</option>
    <option phx-click="select-race" value="dwarf">Dwarf</option>
    <option phx-click="select-race" value="orc">Orc</option>
  </select>
  ```

  We can select an option:

  ```elixir
  session
  |> select("Human", from: "Race")
  ```

  And we'll get an event `"select-race"` with the payload `%{"value" =>
  "human"}`.

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given we have a form that contains this:

  ```html
  <label for="race">Race <span>*</span></label>
  <select id="race" name="race">
    <option value="human">Human</option>
    <option value="elf">Elf</option>
    <option value="dwarf">Dwarf</option>
    <option value="orc">Orc</option>
  </select>
  ```

  We can select an option:

  ```elixir
  session
  |> select("Human", from: "Race", exact: false)
  ```
  """
  def select(session, option, attrs) when (is_binary(option) or is_list(option)) and is_list(attrs) do
    select(session, "select", option, attrs)
  end

  @doc """
  Like `select/3` but you can specify a select's CSS selector (in addition to
  the label).

  Helpful when you have multiple selects with the same label.

  For more on selecting options, see `select/3`.
  """
  def select(session, select_selector, option, attrs) when (is_binary(option) or is_list(option)) and is_list(attrs) do
    opts = Keyword.validate!(attrs, [:from, exact: true, exact_option: true])
    Driver.select(session, select_selector, option, opts)
  end

  @doc """
  Check a checkbox.

  To uncheck a checkbox, see `uncheck/3`.

  ## Options

  - `exact`: whether to match label text exactly. (Defaults to `true`)

  ## Inside a form

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `check/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  ### Example

  Given we have a form that contains this:

  ```html
  <label for="admin">Admin</label>
  <input type="hidden" name="admin" value="off" />
  <input id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can check the "Admin" option:

  ```elixir
  session
  |> check("Admin")
  ```

  ## Outside of a form

  If the checkbox exists outside of a form, `check/3` will trigger the
  `phx-click` event.

  ### Example

  ```html
  <label for="admin">Admin</label>
  <input phx-click="toggle-admin" id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can check the "Admin" option:

  ```elixir
  session
  |> check("Admin")
  ```

  And that will send a `"toggle-admin"` event with the input's `value` as the
  payload.

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given we have a form that contains this:

  ```html
  <label for="admin">Admin <span>*</span></label>
  <input type="hidden" name="admin" value="off" />
  <input id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can check the "Admin" option:

  ```elixir
  session
  |> check("Admin", exact: false)
  ```
  """
  def check(session, label, opts \\ [exact: true])

  def check(session, label, opts) when is_binary(label) and is_list(opts) do
    check(session, "input[type='checkbox']", label, opts)
  end

  def check(session, checkbox_selector, label) when is_binary(label) do
    check(session, checkbox_selector, label, exact: true)
  end

  @doc """
  Like `check/3` but allows you to specify the checkbox's CSS selector.

  Helpful in cases when you have multiple checkboxes with the same label on the
  same form.

  For more on checking boxes, see `check/3`. To uncheck a checkbox, see
  `uncheck/3` and `uncheck/4`.
  """

  def check(session, checkbox_selector, label, opts) when is_binary(label) and is_list(opts) do
    opts = Keyword.validate!(opts, exact: true)
    Driver.check(session, checkbox_selector, label, opts)
  end

  @doc """
  Uncheck a checkbox.

  To check a checkbox, see `check/3`.

  ## Options

  - `exact`: whether to match label text exactly. (Defaults to `true`)

  ## Inside a form

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `uncheck/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  ### Example

  Given we have a form that contains this:

  ```html
  <label for="admin">Admin</label>
  <input type="hidden" name="admin" value="off" />
  <input id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can uncheck the "Admin" option:

  ```elixir
  session
  |> uncheck("Admin")
  ```

  Note that unchecking a checkbox in HTML doesn't actually send any data to the
  server. That's why we have to have a hidden input with the default value (in
  the example above: `admin="off"`).

  ## Outside of a form

  If the checkbox exists outside of a form, `uncheck/3` will trigger the
  `phx-click` event and send an empty (`%{}`) payload.

  ### Example

  ```html
  <label for="admin">Admin</label>
  <input phx-click="toggle-admin" id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can uncheck the "Admin" option:

  ```elixir
  session
  |> uncheck("Admin")
  ```

  And that will send a `"toggle-admin"` event with an empty map `%{}` as a
  payload.

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given we have a form that contains this:

  ```html
  <label for="admin">Admin <span>*</span></label>
  <input type="hidden" name="admin" value="off" />
  <input id="admin" type="checkbox" name="admin" value="on" />
  ```

  We can uncheck the "Admin" option:

  ```elixir
  session
  |> uncheck("Admin", exact: false)
  ```
  """
  def uncheck(session, label, opts \\ [exact: true])

  def uncheck(session, label, opts) when is_binary(label) and is_list(opts) do
    uncheck(session, "input[type='checkbox']", label, opts)
  end

  def uncheck(session, checkbox_selector, label) when is_binary(label) do
    uncheck(session, checkbox_selector, label, exact: true)
  end

  @doc """
  Like `uncheck/3` but allows you to specify the checkbox's CSS selector.

  Helpful when you have multiple checkboxes with the same label. In those cases,
  you might need to specify the selector of the labeled element.

  Note that in those cases, the selector should point to the checkbox that is
  visible, not to the hidden input. For more, see `uncheck/2`.

  For more on unchecking boxes, see `uncheck/3`. To check a checkbox, see
  `check/3` and `check/4`.
  """
  def uncheck(session, checkbox_selector, label, opts) when is_binary(label) and is_list(opts) do
    opts = Keyword.validate!(opts, exact: true)
    Driver.uncheck(session, checkbox_selector, label, opts)
  end

  @doc """
  Choose a radio button option.

  ## Options

  - `exact`: whether to match label text exactly. (Defaults to `true`)

  ## Inside a form

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `choose/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  If the radio button exists outside of a form, `choose/3` will trigger the
  `phx-click` event.

  ### Example

  Given we have a form that contains this:

  ```html
  <input type="radio" id="email" name="contact" value="email" />
  <label for="email">Email</label>

  <input type="radio" id="phone" name="contact" value="phone" />
  <label for="phone">Phone</label>
  ```

  We can choose to be contacted by email:

  ```elixir
  session
  |> choose("Email")
  ```

  ## Outside of a form

  If the checkbox exists outside of a form, `choose/3` will trigger the
  `phx-click` event.

  ### Example

  ```html
  <input phx-click="select-contact" type="radio" id="email" name="contact" value="email" />
  <label for="email">Email</label>
  ```

  We can choose to be contacted by email:

  ```elixir
  session
  |> choose("Email")
  ```

  And we'll get a `"select-contact"` event with the input's value in the payload.

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given we have a form that contains this:

  ```html
  <input type="radio" id="email" name="contact" value="email" />
  <label for="email">Email <span>*</span></label>
  ```

  We can choose to be contacted by email:

  ```elixir
  session
  |> choose("Email", exact: false)
  ```
  """
  def choose(session, label, opts \\ [exact: true])

  def choose(session, label, opts) when is_binary(label) and is_list(opts) do
    choose(session, "input[type='radio']", label, opts)
  end

  def choose(session, radio_selector, label) when is_binary(label) do
    choose(session, radio_selector, label, exact: true)
  end

  @doc """
  Like `choose/3` but you can specify an input's selector (in addition to the
  label).

  Helpful for cases when you have multiple radio buttons with the same label.

  ## Example

  Consider a form containig the following:

  ```heex
  <fieldset>
    <legend>Do you like Elixir:</legend>

    <div>
      <input name="elixir-yes" type="radio" id="elixir-yes" value="yes" />
      <label for="elixir-yes">Yes</label>
    </div>
    <div>
      <input name="elixir-no" type="radio" id="elixir-no" value="no" />
      <label for="elixir-no">No</label>
    </div>
  </fieldset>

  <fieldset>
    <legend>Do you like Erlang:</legend>

    <div>
      <input name="erlang-yes" type="radio" id="erlang-yes" value="yes" />
      <label for="erlang-yes">Yes</label>
    </div>
    <div>
      <input name="erlang-yes" type="radio" id="erlang-no" value="no" />
      <label for="erlang-no">No</label>
    </div>
  </fieldset>
  ```

  Since all radio buttons have the labels "Yes" or "No", you can target a
  specific radio button like so:

  ```elixir
  session
  |> choose("#elixir-yes", "Yes")
  ```
  """
  def choose(session, radio_selector, label, opts) when is_binary(label) and is_list(opts) do
    opts = Keyword.validate!(opts, exact: true)
    Driver.choose(session, radio_selector, label, opts)
  end

  @doc """
  Upload a file.

  If the form is a LiveView form, this will perform a live file upload.

  This can be followed by a `click_button/3` or `submit/1` to submit the form.

  ## Options

  - `exact`: whether to match the entire label. (Defaults to `true`)

  ## Examples

  Given we have a form that contains this:

  ```html
  <label for="avatar">Avatar</label>
  <input type="file" id="avatar" name="avatar" />
  ```

  We can upload a file:

  ```elixir
  session
  |> upload("Avatar", "/path/to/file")
  ```

  ## Complex labels

  If we have a complex label, you can use `exact: false` to target part of the
  label.

  ### Example

  Given the following:

  ```html
  <label for="avatar">Avatar <span>*</span></label>
  <input type="file" id="avatar" name="avatar" />
  ```

  We can upload a file:

  ```elixir
  session
  |> upload("Avatar", "/path/to/file", exact: false)
  ```
  """
  def upload(session, label, path, opts \\ [exact: true])

  def upload(session, label, path, opts) when is_binary(label) and is_binary(path) and is_list(opts) do
    upload(session, "input[type='file']", label, path, opts)
  end

  def upload(session, input_selector, label, path) when is_binary(label) and is_binary(path) do
    upload(session, input_selector, label, path, exact: true)
  end

  @doc """
  Like `upload/4` but you can specify an input's selector (in addition to the
  label).

  Helpful in cases when you have uploads with the same label on the same form.

  For more, see `upload/4`.
  """
  def upload(session, input_selector, label, path, opts) when is_binary(label) and is_binary(path) and is_list(opts) do
    opts = Keyword.validate!(opts, exact: true)
    Driver.upload(session, input_selector, label, path, opts)
  end

  @doc """
  Helper to submit a pre-filled form without clicking a button (see `fill_in/3`,
  `select/3`, `choose/3`, etc. for how to fill a form.)

  Forms are typically submitted by clicking buttons. But sometimes we want to
  emulate what happens when we submit a form hitting <Enter>. That's what this
  helper does.

  If the form is a LiveView form, and if the form has a `phx-submit` attribute
  defined, `submit/1` will trigger the `phx-submit` event. Otherwise, it'll
  submit the form regularly.

  If the form has a submit button with a `name` and `value`, `submit/1` will
  also include that data in the payload.

  ## Example

  ```elixir
  session
  |> fill_in("Name", with: "Aragorn")
  |> select("Human", from: "Race")
  |> choose("Email")
  |> submit()
  ```
  """
  defdelegate submit(session), to: Driver

  @doc """
  Open the default browser to display current HTML of `session`.

  ## Examples

  ```elixir
  session
  |> visit("/")
  |> fill_in("Name", with: "Aragorn")
  |> open_browser()
  |> submit()
  ```
  """
  defdelegate open_browser(session), to: Driver

  @doc false
  defdelegate open_browser(session, open_fun), to: Driver

  @doc """
  Escape hatch to give users access to underlying "native" data structure.

  Once the unwrapped actions are performed, PhoenixTest will handle redirects
  (if any).

  - In LiveView tests, `unwrap/2` will pass the `view` that comes from
  Phoenix.LiveViewTest `live/2`. Your action _must_ return the result of a
  `render_*` LiveViewTest action.

  - In non-LiveView tests, `unwrap/2` will pass the `conn` struct. And your
  action _must_ return a `conn` struct.

  ## Examples

  ```elixir
  # in a LiveView
  session
  |> unwrap(fn view ->
    view
    |> LiveViewTest.element("#hook")
    |> LiveViewTest.render_hook(:hook_event, %{name: "Legolas"})
  end)
  ```

  ```elixir
  # in a non-LiveView
  session
  |> unwrap(fn conn ->
    conn
    |> Phoenix.ConnTest.recycle()
  end)
  ```
  """
  defdelegate unwrap(session, fun), to: Driver

  @doc """
  Assert helper to ensure an element with given CSS selector is present.

  It'll raise an error if no elements are found, but it will _not_ raise if more
  than one matching element is found.

  If you want to specify the content of the element, use `assert_has/3`.

  ## Examples

  ```elixir
  # assert there's an h1
  assert_has(session, "h1")

  # assert there's an element with ID "user"
  assert_has(session, "#user")
  ```
  """
  defdelegate assert_has(session, selector), to: Driver

  @doc """
  Assert helper to ensure an element with given CSS selector and options.

  It'll raise an error if no elements are found, but it will _not_ raise if more
  than one matching element is found.

  ## Options

  - `text`: the text filter to look for.

  - `exact`: by default `assert_has/3` will perform a substring match (e.g. `a
  =~ b`). That makes it easier to assert text within HTML elements that also
  contain other HTML elements. But sometimes we want to assert the exact text is
  present. For that, use `exact: true`. (defaults to `false`)

  - `count`: the number of items you expect to match CSS selector (and `text` if
  provided)

  - `at`: the element to be asserted against

  ## Examples

  ```elixir
  # assert there's an element with ID "user" and text "Aragorn"
  assert_has(session, "#user", text: "Aragorn")
    # ^ succeeds if text found is "Aragorn" or "Aragorn, Son of Arathorn"

  # assert there's an element with ID "user" and text "Aragorn"
  assert_has(session, "#user", text: "Aragorn", exact: true)
    # ^ succeeds only if text found is "Aragorn". Fails if finds "Aragorn, Son of Arathorn"

  # assert there are two elements with class "posts"
  assert_has(session, ".posts", count: 2)

  # assert there are two elements with class "posts" and text "Hello"
  assert_has(session, ".posts", text: "Hello", count: 2)

  # assert the second element in the list of ".posts" has text "Hello"
  assert_has(session, ".posts", at: 2, text: "Hello")
  ```
  """
  defdelegate assert_has(session, selector, opts), to: Driver

  @doc """
  Opposite of `assert_has/2` helper. Verifies that element with
  given CSS selector is _not_ present.

  It'll raise an error if any elements that match selector are found.

  If you want to specify the content of the element, use `refute_has/3`.

  ## Example

  ```elixir
  # refute there's an h1
  refute_has(session, "h1")

  # refute there's an element with ID "user"
  refute_has(session, "#user")
  ```
  """
  defdelegate refute_has(session, selector), to: Driver

  @doc """
  Opposite of `assert_has/3` helper. Verifies that element with
  given CSS selector and `text` is _not_ present.

  It'll raise an error if any elements that match selector and options.

  ## Options

  - `text`: the text filter to look for.

  - `exact`: by default `refute_has/3` will perform a substring match (e.g. `a
  =~ b`). That makes it easier to refute text within HTML elements that also
  contain other HTML elements. But sometimes we want to refute the exact text is
  absent. For that, use `exact: true`.

  - `count`: the number of items you're expecting _should not_ match the CSS
  selector (and `text` if provided)

  - `at`: the element to be refuted against

  ## Examples

  ```elixir
  # refute there's an element with ID "user" and text "Aragorn"
  refute_has(session, "#user", text: "Aragorn")

  # refute there's an element with ID "user" and exact text "Aragorn"
  refute_has(session, "#user", text: "Aragorn", exact: true)

  # refute there are two elements with class "posts" (less or more will not raise)
  refute_has(session, ".posts", count: 2)

  # refute there are two elements with class "posts" and text "Hello"
  refute_has(session, ".posts", text: "Hello", count: 2)

  # refute the second element with class "posts" has text "Hello"
  refute_has(session, ".posts", at: 2, text: "Hello")
  ```
  """
  defdelegate refute_has(session, selector, opts), to: Driver

  @doc """
  Assert helper to verify current request path. Takes an optional `query_params`
  map.

  > ### Note on Live Patch Implementation {: .info}
  >
  > Capturing the current path in live patches relies on message passing and
  could, therefore, be subject to intermittent failures. Please open an issue if
  you see intermittent failures when using `assert_path` with live patches so we
  can improve the implementation.

  ## Examples

  ```elixir
  # assert we're at /users
  conn
  |> visit("/users")
  |> assert_path("/users")

  # assert we're at /users?name=frodo
  conn
  |> visit("/users")
  |> assert_path("/users", query_params: %{name: "frodo"})
  ```
  """
  defdelegate assert_path(session, path), to: Driver

  @doc """
  Same as `assert_path/2` but takes an optional `query_params` map.
  """
  defdelegate assert_path(session, path, opts), to: Driver

  @doc """
  Verifies current request path is NOT the one provided. Takes an optional
  `query_params` map for more specificity.

  > ### Note on Live Patch Implementation {: .info}
  >
  > Capturing the current path in live patches relies on message passing and
  could, therefore, be subject to intermittent failures. Please open an issue if
  you see intermittent failures when using `refute_path` with live patches so we
  can improve the implementation.

  ## Examples

  ```elixir
  # refute we're at /posts
  conn
  |> visit("/users")
  |> refute_path("/posts")

  # refute we're at /users?name=frodo
  conn
  |> visit("/users?name=aragorn")
  |> refute_path("/users", query_params: %{name: "frodo"})
  ```
  """
  defdelegate refute_path(session, path), to: Driver

  @doc """
  Same as `refute_path/2` but takes an optional `query_params` for more specific
  refutation.
  """
  defdelegate refute_path(session, path, opts), to: Driver
end
