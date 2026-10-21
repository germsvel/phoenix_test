# PhoenixTest

[![Module Version](https://img.shields.io/hexpm/v/phoenix_test.svg)](https://hex.pm/packages/phoenix_test/)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_test/)
[![License](https://img.shields.io/hexpm/l/phoenix_test.svg)](https://github.com/germsvel/phoenix_test/blob/main/LICENSE)

PhoenixTest provides a unified way of writing feature tests -- regardless of
whether you're testing LiveView pages or static (non-LiveView) pages.

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
  |> click_button("Create")
  |> assert_has(".user", "Aragorn")
end
```

Note that PhoenixTest does not handle JavaScript. If you're looking for
something that supports JavaScript, take a look at
[Wallaby](https://hexdocs.pm/wallaby/readme.html).

For full documentation, take a look at [PhoenixTest docs](https://hexdocs.pm/phoenix_test/PhoenixTest.html).

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

But if we're testing a static page, we have to resort to controller testing:

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

## What do you mean by "static" pages?

We use the term _static_ as compared to LiveView pages. Thus, in PhoenixTest's
terminology static pages are what is typically known as dynamic, server-rendered
pages -- pages that were normal prior to the advent of LiveView and which are
sometimes called "dead" views. Thus, we do not mean _static_ in the sense that
static-site generators (such as Jekyll, Gatsby, etc.) mean it.

## Development instructions

If you want to contribute and test your changes, here are some helpful steps.

### Prerequisites

1. Install Erlang/OTP and Elixir with versions in [`.tool-versions`](.tool-versions).
2. Run `mix setup`

### Make and test changes

To test your changes, before submitting a PR:

```sh
mix test
OR
mix test.crap
```

The `mix test.crap` alias runs the tests _and_ calculates CRAP scores.

### Verifying with Phoenix's real payloads

We have a set of tests that compare PhoenixTest's params with what Phoenix
actually sends in requests.

To run those browser parity tests, you'll need Node.js (see .tool-versions),
then install the Playwright dependencies, and Chromium:

```sh
mix assets.build
npm --prefix test/verification ci
(cd test/verification && npx playwright install chromium)
mix test test/verification/verification_test.exs --include browser_verification
```

These tests start the test endpoints locally on ports 4000 and 4001; ensure
those ports are available. On Linux, if Chromium needs system libraries, use
`npx playwright install --with-deps chromium` instead of the install command
above.

**Made with ❤️  by [German Velasco]**

[German Velasco]: https://germanvelasco.com
