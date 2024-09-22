defmodule PhoenixTest.SelectTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Select

  describe "find_select_option!" do
    test "returns the selected option value" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 2")

      assert ~s|[id="name"]| = field.selector
      assert ["select_2"] = field.value
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

      field = Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"])

      assert ~s|[id="name"]| = field.selector
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
        Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"])
      end
    end
  end

  describe "belongs_to_form?" do
    test "returns true if field is inside a form" do
      html = """
      <form>
        <label for="name">Name</label>
        <select id="name" name="name">
          <option value="select_1">Select 1</option>
        </select>
      </form>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 1")

      assert Select.belongs_to_form?(field)
    end

    test "returns false if field is outside of a form" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 1")

      refute Select.belongs_to_form?(field)
    end
  end

  describe "phx_click_option?" do
    test "returns true if all option have a phx-click attached" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option phx-click="something" value="select_1">Select 1</option>
        <option phx-click="something" value="select_2">Select 2</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 2")

      assert Select.phx_click_options?(field)
    end

    test "returns false if any option doesn't have e phx-click attached" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name">
        <option phx-click="something" value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 2")

      refute Select.phx_click_options?(field)
    end
  end
end
