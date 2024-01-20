defmodule PhoenixTest do
  @moduledoc """
  PhoenixTest is a testing library that allows you to run your feature tests the
  same way regardless of whether your page is a LiveView or a static view.

  It also handles navigation between LiveView and static pages seamlessly.

  Note that PhoenixTest does not handle JavaScript. If your looking for
  something that supports JavaScript, take a look at [Wallaby].


  ## Example usage

  ```elixir
  session
  |> visit("/")
  |> click_link("Users")
  |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedan.com")
  |> click_button("Create")
  |> assert_has(".user", "Aragorn")
  ```
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

      conn ->
        PhoenixTest.Static.build(conn)
    end
  end

  @doc """
  Clicks a link with given text and performs the action.

  Here's how it handles different types of `a` tags:

  - With `href`: follows it to the next page
  - With `phx-submit`: it'll send the event to the appropriate LiveView
  - With live redirect: it'll follow the live navigation to the next LiveView
  - With live patch: it'll patch the current LiveView
  """
  defdelegate click_link(session, text), to: Driver

  @doc """
  Perfoms action defined by button.

  - If the button has a `phx-click` on it, it'll send the event to the LiveView.

  - If the button doesn't have a `phx-click` on it, it'll submit the parent form.

  This function can be preceded by `fill_form` to fill out a form and
  subsequently submit the form.

  Note that `fill_form/3` + `click_button/2` works for static and live pages.

  If `click_button/2` is used alone (without a `phx-click`), it is assumed it is a
  form with a single button (e.g. "Delete").

  ## Examples

  ```elixir
  # form with single button or button with `phx-click`
  session
  |> click_button("Delete")

  # fill out form and then submit
  session
  |> fill_form("#user-form", name: "Aragorn")
  |> click_button("Create")
  ```
  """
  defdelegate click_button(session, text), to: Driver

  @doc """
  Fills form data, validating that input fields are present.

  This can be used by both static and live pages.

  If it is a LiveView, and if the form has a `phx-change` attribute defined,
  `fill_form/3` will trigger the `phx-change` event.

  This can be followed by a `click_button/3` to submit the form.
  """
  defdelegate fill_form(session, selector, data), to: Driver

  @doc """
  Submits form in the same way one would do by pressing `<Enter>`.

  Note that this does not validate presence of the submit button.

  ## Examples

  ```elixir
  session
  |> submit_form("#user-form", name: "Aragorn")
  ```
  """
  defdelegate submit_form(session, selector, data), to: Driver

  @doc """
  Assert helper to ensure an element with given CSS selector and `text` is
  present.

  It'll raise an error if no elements are found, but it will not raise if more
  than one matching element is found.
  """
  defdelegate assert_has(session, selector, text), to: Assertions

  @doc """
  Opposite of `assert_has/3` helper. Verifies that element with
  given CSS selector and `text` is _not_ present.

  It'll raise an error if an element that matches selector and text is  found.
  """
  defdelegate refute_has(session, selector, text), to: Assertions
end
