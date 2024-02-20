defmodule PhoenixTest.Html.DataAttributeFormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html.DataAttributeForm
  alias PhoenixTest.Query

  describe "build/1" do
    test "builds a form with method, action, csrf_token" do
      element =
        to_element("""
        <a data-method="put" data-to="/users/2" data-csrf="token">
          Delete
        </a>
        """)

      form = DataAttributeForm.build(element)

      assert form.method == "put"
      assert form.action == "/users/2"
      assert form.csrf_token == "token"
    end

    test "includes original element passed to build/1" do
      element =
        to_element("""
        <a data-method="put" data-to="/users/2" data-csrf="token">
          Delete
        </a>
        """)

      form = DataAttributeForm.build(element)

      assert form.element == element
    end

    test "creates form data of what would be hidden inputs in regular form" do
      element =
        to_element("""
        <a data-method="put" data-to="/users/2" data-csrf="token">
          Delete
        </a>
        """)

      form = DataAttributeForm.build(element)

      assert form.data["_method"] == "put"
      assert form.data["_csrf_token"] == "token"
    end
  end

  describe "validate!/1" do
    test "raises an error if data-method is missing" do
      element =
        to_element("""
        <a data-to="/users/2" data-csrf="token">
          Delete
        </a>
        """)

      assert_raise ArgumentError, ~r/missing: data-method/, fn ->
        element
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!("a", "Delete")
      end
    end

    test "raises an error if data-to is missing" do
      element =
        to_element("""
        <a data-method="put" data-csrf="token">
          Delete
        </a>
        """)

      assert_raise ArgumentError, ~r/missing: data-to/, fn ->
        element
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!("a", "Delete")
      end
    end

    test "raises an error if data-csrf is missing" do
      element =
        to_element("""
        <a data-method="put" data-to="/users/2">
          Delete
        </a>
        """)

      assert_raise ArgumentError, ~r/missing: data-csrf/, fn ->
        element
        |> DataAttributeForm.build()
        |> DataAttributeForm.validate!("a", "Delete")
      end
    end
  end

  defp to_element(html) do
    Query.find!(html, "a")
  end
end
