defmodule PhoenixTest.UtilsTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Utils

  describe "stringify_keys_and_values" do
    test "turns atom keys into string keys" do
      original = %{hello: "world"}

      result = Utils.stringify_keys_and_values(original)

      assert %{"hello" => "world"} = result
    end

    test "turns values into string keys" do
      original = %{value: :ok}

      result = Utils.stringify_keys_and_values(original)

      assert %{"value" => "ok"} = result
    end

    test "preserves lists and stringifies values" do
      original = %{greet: [:hello, "hola"]}

      result = Utils.stringify_keys_and_values(original)

      assert %{"greet" => ["hello", "hola"]} = result
    end
  end
end
