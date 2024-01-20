# PhoenixTest

[![Module Version](https://img.shields.io/hexpm/v/phoenix_test.svg)](https://hex.pm/packages/phoenix_test/)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_test/)
[![License](https://img.shields.io/hexpm/l/phoenix_test.svg)](https://github.com/germsvel/phoenix_test/blob/main/LICENSE)

PhoenixTest is a testing library that allows you to run your feature tests the
same way regardless of whether your page is a LiveView or a static view.

It also handles navigation between LiveView and static pages seamlessly. So, you
don't have to worry about what type of page you're visiting. Just write the
tests from the user's perspective.

Note that PhoenixTest does not handle JavaScript. If you're looking for
something that supports JavaScript, take a look at
[Wallaby](https://hexdocs.pm/wallaby/readme.html).

Thus, you can test a flow going from static to LiveView pages and back without
having to worry about the underlying implementation.

It could look something like this:

```elixir
session
|> visit("/")
|> click_link("Users")
|> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedan.com")
|> click_button("Create")
|> assert_has(".user", "Aragorn")
```

### Why PhoenixTest?

Lately, if I'm going to have a page that uses some JavaScript, I use LiveView.
If the page is going to be completely static, I use regular controllers +
views/HTML modules.

The problem is that they have _vastly different_ testing strategies.

If I use LiveView, we have a great set of helpers. But if a page is static, we
have to resort to controller testing that relies solely on `html_response(conn,
200) =~ "Page title"` for assertions.

Instead, I'd like to have a unified way of testing Phoenix apps -- when they
don't have JavaScript.

That's where `PhoenixTest` comes in.

It's the one way to test your Phoenix apps regardless of live or static views.

## Installation

> #### Requirements {: .neutral }
>
> PhoenixTest requires Phoenix `1.7.10` and LiveView `0.20.1`.

Add `phoenix_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_test, "~> 0.1.0", only: test}
  ]
end
```

## Configuration

In `config/test.exs` specify the endpoint to be used for routing requests:

```elixir
config :phoenix_test, :endpoint, MyApp.Endpoint
```

## Setup

All helpers can be included via `import PhoenixTest`.

But since each test needs a `conn` struct, you'll likely want to set up a few
things before that.

To make that easier, it's helpful to create a `FeatureCase` module that can be
used from your tests:

```elixir
defmodule MyAppWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up
  a connection to test feature tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint MyAppWeb.Endpoint

      use MyAppWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      import PhoenixTest # <- here's PhoenixTest
    end
  end
end
```

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
    |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedan.com")
    |> click_button("Create")
    |> assert_has(".user", "Aragorn")
  end
```
