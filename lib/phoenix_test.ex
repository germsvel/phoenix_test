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
      |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedan.com")
      |> click_button("Create")
      |> assert_has(".user", text: "Aragorn")
    end
    ```

    Note that PhoenixTest does _not_ handle JavaScript. If you're looking for
    something that supports JavaScript, take a look at
    [Wallaby](https://hexdocs.pm/wallaby/readme.html).
  """

  alias PhoenixTest.Driver
  alias PhoenixTest.Assertions

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest

  @doc """
  Entrypoint to create a session.

  `visit/2` takes a `Plug.Conn` struct and the path to visit.

  It returns a `session` which the rest of the `PhoenixTest` functions can use.

  Note that `visit/2` is smart enough to know if the page you're visiting is a
  LiveView or a static view. You don't need to worry about which type of page
  you're visiting.
  """
  def visit(conn, path) do
    case get(conn, path) do
      %{assigns: %{live_module: _}} = conn ->
        PhoenixTest.Live.build(conn)

      %{status: 302} = conn ->
        path = redirected_to(conn)
        visit(conn, path)

      conn ->
        PhoenixTest.Static.build(conn)
    end
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

  ```heex
  <a href="/users/2" data-method="delete" data-to="/users/2" data-csrf="token">
    Delete
  </a>
  ```

  ```elixir
  session
  |> click_link("Delete") # <- will submit form like Phoenix.HTML.js does
  ```
  """
  defdelegate click_link(session, text), to: Driver

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

  ```heex
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

  ```heex
  <button data-method="delete" data-to="/users/2" data-csrf="token">Delete</button>
  ```

  ```elixir
  session
  |> click_button("Delete") # <- will submit form like Phoenix.HTML.js does
  ```

  ## Combined with `fill_form/3`

  This function can be preceded by `fill_form` to fill out a form and
  subsequently submit the form.

  Note that `fill_form/3` + `click_button/2` works for both static and live
  pages.

  ### Example

  ```elixir
  session
  |> fill_form("#user-form", name: "Aragorn")
  |> click_button("Create")
  ```

  ## Single-button form

  If `click_button/2` is used alone (without `phx-click`, `data-*` attrs, or
  `fill_form/3`), it is assumed it is a form with a single button (e.g.
  "Delete").

  ### Example

  ```heex
  <form method="post" action="/users/2">
    <input type="hidden" name="_method" value="delete" />
    <button>Delete</button>
  </form>
  ```

  ```elixir
  session
  |> click_button("Delete") # <- Triggers full form delete
  ```
  """
  defdelegate click_button(session, text), to: Driver

  @doc """
  Performs action defined by button with CSS selector.

  See `click_button/2` for more details.
  """
  defdelegate click_button(session, selector, text), to: Driver

  @doc false
  defdelegate within(session, selector, fun), to: Driver

  @doc false
  defdelegate fill_in(session, label, attrs), to: Driver

  @doc false
  defdelegate select(session, option, attrs), to: Driver

  @doc false
  defdelegate check(session, label), to: Driver

  @doc false
  defdelegate uncheck(session, label), to: Driver

  @doc false
  defdelegate choose(session, label), to: Driver

  @doc false
  defdelegate submit(session), to: Driver

  @doc """
  Fills form data, validating that input fields are present.

  This can be used by both static and live pages.

  If the form is a LiveView form, and if the form has a `phx-change` attribute
  defined, `fill_form/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` to submit the form.

  ## Examples

  ```elixir
  session
  |> fill_form("#user-form", name: "Aragorn")
  |> click_button("Create")
  ```

  If your form has nested data -- for example, with an input such as `<input
  name="user[email]">` -- you can pass a nested map as the last argument:

  ```elixir
  session
  |> fill_form("#user-form", user: %{email: "aragorn@dunedain.com"})
  |> click_button("Create")
  ```
  """
  defdelegate fill_form(session, selector, data), to: Driver

  @doc """
  Submits form in the same way one would do by pressing `<Enter>`.

  _Note that this does not validate presence of the submit button._

  In the case of LiveView forms, it'll submit the form with LiveView's
  `phx-submit` event.

  If it's a static form, this is equivalent to filling the form and submitting
  it with the form's `method` and to the form's `action`.

  Note: if your form has a submit button, it's recommended you test with
  `fill_form/3` + `click_button/2` instead.

  ## Examples

  ```elixir
  session
  |> submit_form("#user-form", name: "Aragorn")
  ```

  If your form has nested data -- for example, with an input such as `<input
  name="user[email]">` -- you can pass a nested map as the last argument:

  ```elixir
  session
  |> submit_form("#user-form", user: %{email: "aragorn@dunedain.com"})
  ```
  """
  defdelegate submit_form(session, selector, data), to: Driver

  @doc """
  Open the default browser to display current HTML of `session`.

  ## Examples

  ```elixir
  session
  |> visit("/")
  |> open_browser()
  |> submit_form("#user-form", name: "Aragorn")
  ```
  """
  defdelegate open_browser(session), to: Driver

  @doc false
  defdelegate open_browser(session, open_fun), to: Driver

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
  defdelegate assert_has(session, selector), to: Assertions

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
  defdelegate assert_has(session, selector, opts), to: Assertions

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
  defdelegate refute_has(session, selector), to: Assertions

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
  defdelegate refute_has(session, selector, opts), to: Assertions

  @doc """
  Assert helper to verify current request path. Takes an optional `query_params`
  map.

  > ### Limited live patch implementation {: .warning}
  >
  > The current `assert_path` implementation doesn't support live patches.

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
  defdelegate assert_path(session, path), to: Assertions

  @doc """
  Same as `assert_path/2` but takes an optional `query_params` map.
  """
  defdelegate assert_path(session, path, opts), to: Assertions

  @doc """
  Verifies current request path is NOT the one provided. Takes an optional
  `query_params` map for more specificity.

  > ### Limited live patch implementation {: .warning}
  >
  > The current `refute_path` implementation doesn't support live patches.

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
  defdelegate refute_path(session, path), to: Assertions

  @doc """
  Same as `refute_path/2` but takes an optional `query_params` for more specific
  refutation.
  """
  defdelegate refute_path(session, path, opts), to: Assertions
end
