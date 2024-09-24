defmodule PhoenixTest.FormDataTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Field
  alias PhoenixTest.FormData

  describe "to_form_data!" do
    test "transforms a field into a name/value pair" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" name="name" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name")

      assert [{"name", "Hello world"}] = FormData.to_form_data!(field)
    end

    test "raises error if name attribute is missing" do
      html = """
      <label for="name">Name</label>
      <input id="name" type="text" value="Hello world"/>
      """

      field = Field.find_input!(html, "input", "Name")

      assert_raise ArgumentError, ~r/missing a `name`/, fn ->
        FormData.to_form_data!(field)
      end
    end
  end
end
