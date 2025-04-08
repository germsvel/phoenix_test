defmodule PhoenixTest.FormDataTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select
  alias PhoenixTest.FormData

  describe "add_data" do
    test "adds new data to existing data" do
      form_data =
        FormData.new()
        |> FormData.add_data("name", "frodo")
        |> FormData.add_data("email", "frodo@example.com")

      assert FormData.has_data?(form_data, "name", "frodo")
      assert FormData.has_data?(form_data, "email", "frodo@example.com")
    end

    test "adds new data whose value is a list" do
      form_data = FormData.add_data(FormData.new(), "name", ["value_1", "value_2"])

      assert FormData.has_data?(form_data, "name", "value_1")
      assert FormData.has_data?(form_data, "name", "value_2")
    end

    test "does not add data when name is nil" do
      form_data = FormData.add_data(FormData.new(), nil, "value")

      assert FormData.empty?(form_data)
    end

    test "adds Field (name/value)" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name", exact: true)

      form_data = FormData.add_data(FormData.new(), field)

      assert FormData.has_data?(form_data, "name", "Hello world")
    end

    test "adds Button (name/value)" do
      button = %Button{name: "name", value: "Frodo"}

      form_data = FormData.add_data(FormData.new(), button)

      assert FormData.has_data?(form_data, "name", "Frodo")
    end

    test "doesn't add button data if Button doesn't have name and value" do
      button = %Button{}

      form_data = FormData.add_data(FormData.new(), button)

      assert FormData.empty?(form_data)
    end

    test "adds single Selected value as list of name/value pairs" do
      html = """
      <label for="name">Name</label>
      <select id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      select = Select.find_select_option!(html, "select", "Name", "Select 1", exact: true)

      form_data = FormData.add_data(FormData.new(), select)

      assert FormData.has_data?(form_data, "name", "select_1")
    end

    test "adds list of Selected values into list of name/value pairs" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      select = Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"], exact: true)
      form_data = FormData.add_data(FormData.new(), select)

      assert FormData.has_data?(form_data, "name", "select_2")
      assert FormData.has_data?(form_data, "name", "select_3")
    end

    test "adds Field data as a name/value pair" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name", exact: true)
      form_data = FormData.add_data(FormData.new(), field)

      assert FormData.has_data?(form_data, "name", "Hello world")
    end

    test "does not duplicate list data (with same name with [] and same value)" do
      form_data =
        FormData.new()
        |> FormData.add_data("email[]", "value")
        |> FormData.add_data("email[]", "value")

      data = FormData.to_list(form_data)

      assert data == [{"email[]", "value"}]
    end

    test "preserves multiple entries with different values if name has []" do
      form_data =
        FormData.new()
        |> FormData.add_data("email[]", "value")
        |> FormData.add_data("email[]", "value2")

      assert FormData.has_data?(form_data, "email[]", "value")
      assert FormData.has_data?(form_data, "email[]", "value2")
    end

    test "adds a list of data" do
      form_data =
        FormData.add_data(FormData.new(), [{"name", "frodo"}, {"email", "frodo@example.com"}])

      assert FormData.has_data?(form_data, "name", "frodo")
      assert FormData.has_data?(form_data, "email", "frodo@example.com")
    end
  end

  describe "merge" do
    test "combines two FormData" do
      fd1 =
        FormData.add_data(FormData.new(), "name", "frodo")

      fd2 =
        FormData.add_data(FormData.new(), "email", "frodo@fellowship.com")

      form_data = FormData.merge(fd1, fd2)

      assert FormData.has_data?(form_data, "name", "frodo")
      assert FormData.has_data?(form_data, "email", "frodo@fellowship.com")
    end
  end

  describe "filter" do
    test "filters form data based on function provivded" do
      form_data =
        FormData.new()
        |> FormData.add_data("name", "frodo")
        |> FormData.add_data("email", "frodo@fellowship.com")

      filtered_data =
        FormData.filter(form_data, fn %{name: name, value: value} ->
          name == "name" and value == "frodo"
        end)

      assert FormData.has_data?(filtered_data, "name", "frodo")
      refute FormData.has_data?(filtered_data, "email", "frodo@fellowship.com")
    end
  end

  describe "empty?" do
    test "returns true if there's no data" do
      assert FormData.empty?(FormData.new())
    end

    test "returns false if it has some data" do
      form_data =
        FormData.add_data(FormData.new(), "name", "frodo")

      refute FormData.empty?(form_data)
    end
  end

  describe "to_list" do
    test "transforms FormData into a list" do
      form_data =
        FormData.new()
        |> FormData.add_data("name", "frodo")
        |> FormData.add_data("email", "frodo@fellowship.com")

      list = FormData.to_list(form_data)

      assert list == [{"email", "frodo@fellowship.com"}, {"name", "frodo"}]
    end

    test "preserves select options ordering" do
      html = """
      <label for="name">Name</label>
      <select multiple id="name" name="name[]">
        <option value="select_1">Select 1</option>
        <option value="select_2">Select 2</option>
        <option value="select_3">Select 3</option>
      </select>
      """

      select = Select.find_select_option!(html, "select", "Name", ["Select 2", "Select 3"], exact: true)
      form_data = FormData.add_data(FormData.new(), select)

      assert FormData.to_list(form_data) == [
               {"name[]", "select_2"},
               {"name[]", "select_3"}
             ]
    end

    test "only returns one name (preserving of operations when deduplicating data)" do
      form_data =
        FormData.new()
        |> FormData.add_data("email", "value")
        |> FormData.add_data("email", "other_value")
        |> FormData.add_data("email", "third_value")

      data = FormData.to_list(form_data)

      assert data == [{"email", "third_value"}]
    end
  end
end
