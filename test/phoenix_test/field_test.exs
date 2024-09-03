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

      assert %{selector: ~s|[id="name"]|} = field
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

  describe "phx_click?" do
    test "returns true if field has a phx-click handler" do
      html = """
      <label for="name">Name</label>
      <input phx-click="save" id="name" type="radio" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "Name")

      assert Field.phx_click?(field)
    end

    test "returns false if field doesn't have a phx-click handler" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="radio" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "Name")

      refute Field.phx_click?(field)
    end
  end

  describe "belongs_to_form?" do
    test "returns true if field is inside a form" do
      html = """
      <form>
        <label for="name">Name</label>
        <input id="name" type="text" name="name" value="Hello world"/>
      </form>
      """

      field = Field.find_input!(html, "Name")

      assert Field.belongs_to_form?(field)
    end

    test "returns false if field is outside of a form" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "Name")

      refute Field.belongs_to_form?(field)
    end
  end
end
