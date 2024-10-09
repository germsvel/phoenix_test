defmodule PhoenixTest.FormDataTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.FormData
  alias PhoenixTest.Select

  describe "add_data" do
    test "adds new data to existing data" do
      name = FormData.to_form_data("name", "frodo")
      email = FormData.to_form_data("email", "frodo@example.com")

      form_data =
        FormData.new()
        |> FormData.add_data(name)
        |> FormData.add_data(email)

      assert {"name", "frodo"} in form_data
      assert {"email", "frodo@example.com"} in form_data
    end
  end

  describe "to_form_data for Button" do
    test "transforms a button into a name/value pair" do
      button = %Button{name: "name", value: "Frodo"}

      assert [{"name", "Frodo"}] = FormData.to_form_data(button)
    end

    test "returns empty record if button doesn't have name and value" do
      button = %Button{}

      assert [] = FormData.to_form_data(button)
    end
  end

  describe "to_form_data for Select" do
    test "transforms single selected value into list of name/value pairs" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      select = Select.find_select_option!(html, "select", "Name", "Select 1", exact: true)

      assert [{"name", "select_1"}] = FormData.to_form_data(select)
    end

    test "transforms list of selected values into list of name/value pairs" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      select = Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"], exact: true)

      assert [{"name", "select_2"}, {"name", "select_3"}] = FormData.to_form_data(select)
    end
  end

  describe "to_form_data for Field" do
    test "transforms a field into a name/value pair" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name", exact: true)

      assert [{"name", "Hello world"}] = FormData.to_form_data(field)
    end

    test "raises error if name attribute is missing" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name", exact: true)

      assert_raise ArgumentError, ~r/missing a `name`/, fn ->
        FormData.to_form_data(field)
      end
    end
  end

  describe "to_form_data" do
    test "returns list of name and values when multiple values are passed" do
      result = FormData.to_form_data("name", ["value_1", "value_2"])

      assert result == [{"name", "value_1"}, {"name", "value_2"}]
    end

    test "returns the name and value as list when single value is passed" do
      result = FormData.to_form_data("name", "value")

      assert result == [{"name", "value"}]
    end

    test "returns empty list when name is nil" do
      result = FormData.to_form_data(nil, "value")

      assert result == []
    end
  end
end
