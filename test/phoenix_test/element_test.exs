defmodule PhoenixTest.ElementTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element
  alias PhoenixTest.Query

  describe "build_selector/2" do
    test "builds a selector based on id if id is present" do
      data =
        Query.find!(
          """
          <input id="name" type="text" name="name" value="Hello world"/>
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s|[id="name"]| = selector
    end

    test "builds a composite selector if id isn't present" do
      data =
        Query.find!(
          """
          <input type="text" name="name" />
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s(input[type="text"][name="name"]) = selector
    end

    test "ignores `phx-*` attributes when id isn't present" do
      data =
        Query.find!(
          """
          <input phx-click="ignore-complex-liveview-js" type="text" name="name" />
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s(input[type="text"][name="name"]) = selector
    end
  end

  describe "selector_has_id?" do
    test "returns true if selector has #<id>" do
      selector = "#name"

      assert Element.selector_has_id?(selector)
    end

    test "returns true if selector has [id=<id>]" do
      selector = "[id='name']"

      assert Element.selector_has_id?(selector)
    end

    test "returns false if selector doesn't have id" do
      selector = "[data-role='name']"

      refute Element.selector_has_id?(selector)
    end
  end
end
