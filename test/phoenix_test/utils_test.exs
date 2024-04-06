defmodule PhoenixTest.UtilsTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Utils

  describe "name_to_map/2" do
    test "expands single word name into map" do
      name = "user"

      result = Utils.name_to_map(name, "Aragorn")

      assert %{"user" => "Aragorn"} = result
    end

    test "expands nested input names into nested maps" do
      name = "user[name][first]"

      result = Utils.name_to_map(name, "Aragorn")

      assert %{"user" => %{"name" => %{"first" => "Aragorn"}}} = result
    end

    test "preserves dashes in name" do
      name = "admin-user[name][first]"

      result = Utils.name_to_map(name, "Aragorn")

      assert %{"admin-user" => %{"name" => %{"first" => "Aragorn"}}} = result
    end

    test "preserves underscores in names" do
      name = "admin_user[name][first]"

      result = Utils.name_to_map(name, "Aragorn")

      assert %{"admin_user" => %{"name" => %{"first" => "Aragorn"}}} = result
    end
  end
end
