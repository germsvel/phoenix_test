defmodule PhoenixTest.Html.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  describe "parse/1" do
    test "parses text inputs" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label name="email">Email</label>
            <input type="text" name="email" value="Aragorn" />
          </form>
        """)

      %{"fields" => fields} = Html.Form.parse(data)

      email = Enum.find(fields, &(&1["name"] == "email"))

      assert %{"type" => "text", "value" => "Aragorn"} = email
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

      %{"fields" => fields} = Html.Form.parse(data)

      race = Enum.find(fields, &(&1["name"] == "race"))

      assert %{"type" => "select", "options" => options} = race
      assert %{"type" => "option", "value" => "human", "content" => "Human"} = hd(options)
    end

    test "parses checkboxes" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label for="admin">Admin</label>
            <input type="checkbox" name="admin" />
          </form>
        """)

      %{"fields" => fields} = Html.Form.parse(data)

      admin = Enum.find(fields, &(&1["name"] == "admin"))

      assert %{"type" => "checkbox"} = admin
    end
  end

  defp form_data(html_form) do
    html_form
    |> Query.find!("form")
  end
end
