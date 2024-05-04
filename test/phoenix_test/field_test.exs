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

  describe "find_select_option!" do
    test "returns the selected option value" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
      </select>
      """

      field = Field.find_select_option!(html, "Name", "Select 2")

      assert "#name" = field.selector
      assert "select_2" = field.value
    end

    test "returns multiple selected option value" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      field = Field.find_select_option!(html, "Name", ["Select 2", "Select 3"])

      assert "#name" = field.selector
      assert ["select_2", "select_3"] = field.value
    end

    test "returns multiple selected option value without multiple attribute to select raises error" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      assert_raise ArgumentError, ~r/Could not find a select with a "multiple" attribute set/, fn ->
        Field.find_select_option!(html, "Name", ["Select 2", "Select 3"])
      end
    end
  end
end
