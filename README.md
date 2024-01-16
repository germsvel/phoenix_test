# PhoenixTest

> Run your tests the same way regardless of whether you're using LiveView or
> static views.

Lately, if I'm going to have a page that uses some JavaScript, I use LiveView.
If the page is going to be completely static, I use regular controllers +
views/HTML modules.

The problem is that they have vastly different testing strategies.

If I use LiveView, we have a great set of helpers. But if a page is static, we
have to resort to controller testing that relies solely on `html =~ "Page
title"` for assertions.

I'd like to have a unified way of testing Phoenix apps -- when they don't have
JavaScript.

That's where `PhoenixTest` comes in.

It's the one way to test your Phoenix apps regardless of live or static views.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `phoenix_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_test, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/phoenix_test>.
