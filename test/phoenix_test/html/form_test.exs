defmodule PhoenixTest.Html.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  describe "build/1" do
    test "sets get as the form's operative_method by default" do
      data =
        form_data("""
          <form id="user-form" action="/">
          </form>
        """)

      %{"operative_method" => method} = Html.Form.build(data)

      assert method == "get"
    end

    test "sets form method as operative_method if present" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
          </form>
        """)

      %{"operative_method" => method} = Html.Form.build(data)

      assert method == "post"
    end

    test "sets operative_method based on hidden input if available" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <input type="hidden" name="_method" value="put"/>
          </form>
        """)

      %{"operative_method" => method} = Html.Form.build(data)

      assert method == "put"
    end

    test "includes attributes" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
          </form>
        """)

      %{"attributes" => attrs} = Html.Form.build(data)

      assert attrs["id"] == "user-form"
      assert attrs["action"] == "/"
      assert attrs["method"] == "post"
    end

    test "parses text inputs" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label name="email">Email</label>
            <input type="text" name="email" value="Aragorn" />
          </form>
        """)

      %{"fields" => fields} = Html.Form.build(data)

      email = Enum.find(fields, &(&1["attributes"]["name"] == "email"))

      assert %{"tag" => "input"} = email
      assert %{"type" => "text", "value" => "Aragorn"} = email["attributes"]
    end

    test "parses selects" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label for="race">Race</label>
            <select name="race">
              <option value="human">Human</option>
              <option value="elf">Elf</option>
              <option value="dwarf">Dwarf</option>
              <option value="orc">Orc</option>
            </select>
          </form>
        """)

      %{"fields" => fields} = Html.Form.build(data)

      race =
        Enum.find(fields, &(&1["attributes"]["name"] == "race"))

      assert %{"tag" => "select", "options" => options} = race
      assert %{"tag" => "option", "content" => "Human"} = hd(options)
      assert %{"value" => "human"} = hd(options)["attributes"]
    end

    test "parses checkboxes" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label for="admin">Admin</label>
            <input type="checkbox" name="admin" />
          </form>
        """)

      %{"fields" => fields} = Html.Form.build(data)

      admin = Enum.find(fields, &(&1["attributes"]["name"] == "admin"))

      assert %{"type" => "checkbox"} = admin["attributes"]
    end

    test "parses nested checkbox" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <div>
              <label for="admin">Admin</label>
              <input type="checkbox" name="admin" />
            </div>
          </form>
        """)

      %{"fields" => fields} = Html.Form.build(data)

      admin = Enum.find(fields, &(&1["attributes"]["name"] == "admin"))

      assert %{"type" => "checkbox"} = admin["attributes"]
    end
  end

  describe "validate_form_data!" do
    test "returns :ok with valid form" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <div>
              <label for="admin">Admin</label>
              <input type="checkbox" name="admin" />
            </div>
          </form>
        """)

      form = Html.Form.build(data)

      assert :ok = Html.Form.validate_form_data!(form, %{admin: "on"})
    end

    test "raises when form doesn't have an action" do
      data =
        form_data("""
          <form>
          </form>
        """)

      form = Html.Form.build(data)

      assert_raise ArgumentError, "Expected form to have an action but found none", fn ->
        Html.Form.validate_form_data!(form, %{})
      end
    end
  end

  describe "validate_form_fields!" do
    test "returns :ok with valid form fields" do
      form =
        """
          <form id="user-form" action="/" method="post">
            <div>
              <label for="admin">Admin</label>
              <input type="checkbox" name="admin" />
            </div>
          </form>
        """
        |> form_data()
        |> Html.Form.build()

      fields = form["fields"]

      assert :ok = Html.Form.validate_form_fields!(fields, %{admin: "on"})
    end

    test "raises when there are no form fields but some are expected" do
      expected_fields = %{admin: "on", name: "Fred"}

      form =
        """
          <form id="user-form" action="/" method="post">
          </form>
        """
        |> form_data()
        |> Html.Form.build()

      msg = """
      Expected form to have "name" form field, but found none.
      """

      assert_raise ArgumentError, msg, fn ->
        Html.Form.validate_form_fields!(form["fields"], expected_fields)
      end
    end

    test "raises when expected field isn't found on form" do
      expected_fields = %{admin: "on", name: "Fred"}

      form =
        """
          <form id="user-form" action="/" method="post">
            <div>
              <label for="admin">Admin</label>
              <input type="checkbox" name="admin" />
            </div>
          </form>
        """
        |> form_data()
        |> Html.Form.build()

      msg = """
      Expected form to have "name" form field, but found none.

      Found the following fields:

      <input name="admin" type="checkbox"/>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Html.Form.validate_form_fields!(form["fields"], expected_fields)
      end
    end
  end

  defp form_data(html_form) do
    Query.find!(html_form, "form")
  end
end
