defmodule PhoenixTest.LocatorsTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Locators
  alias PhoenixTest.Locators.Button

  describe "button" do
    test "includes provided text" do
      %Button{text: text} = Locators.button(text: "Hello")

      assert text == "Hello"
    end

    test "has list of valid selectors" do
      valid_selectors =
        ~w|button [role="button"] input[type="button"] input[type="image"] input[type="reset"] input[type="submit"]|

      %Button{selectors: selectors} = Locators.button(text: "doesn't matter")

      assert selectors == valid_selectors
    end
  end

  describe "role_selectors/1 for button" do
    test "returns {'button', text} in list" do
      locator = Locators.button(text: "Hello")

      selectors = Locators.role_selectors(locator)

      assert {"button", "Hello"} in selectors
    end

    test "returns {[role=button], text} in list" do
      locator = Locators.button(text: "Hello")

      selectors = Locators.role_selectors(locator)

      assert {~s|[role="button"]|, "Hello"} in selectors
    end

    test "returns text as value for other selectors" do
      locator = Locators.button(text: "Hello")

      selectors = Locators.role_selectors(locator)

      assert ~s|input[type="button"][value="Hello"]| in selectors
    end
  end
end
