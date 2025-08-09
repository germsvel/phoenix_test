defmodule PhoenixTest.Element.SelectTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Select

  describe "find_select_option!" do
    test "returns the selected option value" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 2", exact: true)

      assert ~s|[id="name"]| = field.selector
      assert ["select_2"] = field.value
    end

    test "finds select nested in label" do
      html = """
      <label>
        Name
        <select id="name" name="name">
          <option value="select_1">Select 1</option>
          <option value="select_2">Select 2</option>
        </select>
      </label>
      """

      assert_raise ArgumentError, fn ->
        Select.find_select_option!(html, "select", "Name", "Select 2", exact: true)
      end

      field = Select.find_select_option!(html, "select", "Name", "Select 2", exact: false)

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

      field = Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"], exact: true)

      assert ~s|[id="name"]| = field.selector
      assert ["select_2", "select_3"] = field.value
    end

    test "can target option with substring match" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name">
        <option value="one">One</option>
        <option value="two">Two</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "On", exact_option: false)

      assert ~s|[id="name"]| = field.selector
      assert ["one"] = field.value
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
        Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"], exact: true)
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

      field = Select.find_select_option!(html, "select", "Name", "Select 1", exact: true)

      assert Select.belongs_to_form?(field)
    end

    test "returns false if field is outside of a form" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
      </select>
      """

      field = Select.find_select_option!(html, "select", "Name", "Select 1", exact: true)

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

      field = Select.find_select_option!(html, "select", "Name", "Select 2", exact: true)

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

      field = Select.find_select_option!(html, "select", "Name", "Select 2", exact: true)

      refute Select.phx_click_options?(field)
    end
  end
end
