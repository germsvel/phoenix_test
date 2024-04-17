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

      assert %{source_raw: ^html, id: "name", label: "Name", name: "name", value: "Hello world"} =
               field
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

      assert %{source_raw: ^html, id: "elf", label: "Elf", name: "race", value: "elf"} = field
    end

    test "finds input if nested inside label (and no id)" do
      html = """
      <label>
        Name
        <input type="text" name="name" value="Hello world"/>
      </label>
      """

      field = Field.find_input!(html, "Name")

      assert %{source_raw: ^html, label: "Name", name: "name", value: "Hello world"} = field
    end

    test "builds a selector based on id if id is present" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "Name")

      assert %{selector: "#name"} = field
    end

    test "builds a composite selector if id isn't present" do
      html = """
      <label>
        Name
        <input type="text" name="name" />
      </label>
      """

      field = Field.find_input!(html, "Name")

      assert ~s(input[type="text"][name="name"]) = field.selector
    end
  end
end
