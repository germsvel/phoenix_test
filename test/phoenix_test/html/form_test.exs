defmodule PhoenixTest.Html.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  describe "parse/1" do
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

  defp form_data(html_form) do
    html_form
    |> Query.find!("form")
  end
end
