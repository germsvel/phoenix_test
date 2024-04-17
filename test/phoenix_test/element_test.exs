defmodule PhoenixTest.ElementTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element
  alias PhoenixTest.Query

  describe "build_selector/2" do
    test "builds a selector based on id if id is present" do
      data =
        """
        <input id="name" type="text" name="name" value="Hello world"/>
        """
        |> Query.find!("input")

      selector = Element.build_selector(data)

      assert "#name" = selector
    end

    test "builds a composite selector if id isn't present" do
      data =
        """
        <input type="text" name="name" />
        """
        |> Query.find!("input")

      selector = Element.build_selector(data)

      assert ~s(input[type="text"][name="name"]) = selector
    end
  end
end
