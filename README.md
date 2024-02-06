# PhoenixTest

[![Module Version](https://img.shields.io/hexpm/v/phoenix_test.svg)](https://hex.pm/packages/phoenix_test/)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_test/)
[![License](https://img.shields.io/hexpm/l/phoenix_test.svg)](https://github.com/germsvel/phoenix_test/blob/main/LICENSE)

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
  |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedain.com")
  |> click_button("Create")
  |> assert_has(".user", "Aragorn")
end
```

Note that PhoenixTest does not handle JavaScript. If you're looking for
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
    {:phoenix_test, "~> 0.1.0", only: :test, runtime: false}
  ]
end
```

### Configuration

In `config/test.exs` specify the endpoint to be used for routing requests:

```elixir
config :phoenix_test, :endpoint, MyAppWeb.Endpoint
```

### Adding a `FeatureCase`

`PhoenixTest` helpers can be included via `import PhoenixTest`.

But since each test needs a `conn` struct to get started, you'll likely want to
set up a few things before that.

To make that easier, it's helpful to create a `FeatureCase` module that can be
used from your tests (replace `MyApp` with your app's name):

```elixir
defmodule MyAppWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up
  a connection to test feature tests.

  Such tests rely on `PhoenixTest` and also import other functionality to
  make it easier to build common data structures and interact with pages.

  Finally, if the test case interacts with the database, we enable the SQL
  sandbox, so changes done to the database are reverted at the end of every
  test. If you are using PostgreSQL, you can even run database tests
  asynchronously by setting `use MyAppWeb.FeatureCase, async: true`, although
  this option is not recommended for other databases.
  """

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
`SQL.Sanbox`. If it doesn't, feel free to remove the `SQl.Sandbox` code above.

## Usage

Now, you can create your tests like this:

```elixir
# test/my_app_web/features/admin_can_create_user_test.exs

defmodule MyAppWeb.AdminCanCreateUserTest do
  use MyAppWeb.FeatureCase, async: true

  test "admin can create user", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Users")
    |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedain.com")
    |> click_button("Create")
    |> assert_has(".user", "Aragorn")
  end
```

For full documentation, take a look at [PhoenixTest module docs](file:///Users/germanvelasco/germsvel/phoenix_test/doc/PhoenixTest.html).

## Why PhoenixTest?

### A unified way of writing feature tests

With the advent of LiveView, I find myself writing less and less JavaScript.

Sure, there are sprinkles of it here and there, and there’s always the
occasional need for something more.

But for the most part:

- If I’m going to build a page that needs interactivity, I use LiveView.
- If I’m going to write a static page, I use regular controllers + views/HTML
  modules.

The problem is that LiveView pages and static pages have _vastly different_
testing strategies.

If we use LiveView, we have a good set of helpers.

```elixir
{:ok, view, _html} = live(conn, ~p"/")

html =
  view
  |> element("#greet-guest")
  |> render_click()

assert html =~ "Hello, guest!"
```

But if we're testing a page is static, we have to resort to controller testing:

```elixir
conn = get(conn, ~p"/greet_page")

assert html_response(conn, 200) =~ "Hello, guest!"
```

That means we don’t have ways of interacting with static pages at all!

What if we want to submit a form or click a link? And what if a click takes us
from a LiveView to a static view or vice versa?

Instead, I'd like to have a unified way of testing Phoenix apps -- regardless of
whether we're testing LiveView pages or static pages.

### Improved assertions

And then there's the problem of assertions.

Because LiveView and controller tests use `=~` for assertions, the error
messages aren't very helpful when assertions fail.

After all, we’re just comparing two blobs of text – and trust me, HTML pages can
get very large and hard to read as a blob of text in your terminal.

LiveView tries to help with its `has_element?/3` helper, which allows us to
target elements by CSS selectors and text.

Unfortunately, it still doesn't provide the best errors.

`has_element?/3` only tells us what was passed into the function. It doesn't
give us a clue as to what else might've been on the page – maybe we just made a
small typo and we have no idea!

And that's where `PhoenixTest` comes in! A unified way of writing feature tests
and improved assertions where they're needed!

## Sponsors

Made possible thanks to:

<a href="https://www.elixirstreams.com">
  <figure>
    <img height="100" width="100" src="https://www.elixirstreams.com/assets/images/elixir-streams-logo-transparent.png">
    <figcaption>Elixir Streams</figcaption>
  </figure>
</a>
