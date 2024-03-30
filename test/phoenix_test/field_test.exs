defmodule PhoenixTest.FieldTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Field

  describe "find_input!" do
    test "finds text field" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "Name")

      assert %{html: ^html, id: "name", label: "Name", name: "name", value: "Hello world"} = field
    end

    test "allows overriding of value" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name"/>
      """

      field = Field.find_input!(html, "Name", "Hello world")

      assert %{html: ^html, id: "name", label: "Name", name: "name", value: "Hello world"} = field
    end

    test "finds radio button specified by label" do
      html = """
      <label for="human">Human</label>
      <input id="human" type="radio" name="race" value="human"/>

      <label for="elf">Elf</label>
      <input id="elf" type="radio" name="race" value="elf"/>

      <label for="orc">Orc</label>
      <input id="orc" type="radio" name="race" value="orc"/>
      """

      field = Field.find_input!(html, "Elf")

      assert %{html: ^html, id: "elf", label: "Elf", name: "race", value: "elf"} = field
    end
  end
end
