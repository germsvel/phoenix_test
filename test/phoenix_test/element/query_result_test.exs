defmodule PhoenixTest.Element.QueryResultTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Element.Link
  alias PhoenixTest.Element.Select
  alias PhoenixTest.Query.Failure

  test "element lookups return query results" do
    html = """
    <form id="profile">
      <label for="name">Name</label>
      <input id="name" name="name" value="Ada" />
      <label for="role">Role</label>
      <select id="role" name="role"><option value="admin">Admin</option></select>
      <button>Save</button>
      <a href="/help">Help</a>
    </form>
    """

    assert {:ok, %{name: "name"}} = Field.find_input(html, "input", "Name", exact: true)
    assert {:ok, %{value: ["admin"]}} = Select.find_select_option(html, "select", "Role", "Admin", exact: true)
    assert {:ok, %{id: "profile"}} = Form.find(html, "#profile")
    assert {:ok, %{text: "Save"}} = Button.find(html, "button", "Save")
    assert {:ok, %{href: "/help"}} = Link.find(html, "a", "Help")
  end

  test "element lookup failures remain query failure data" do
    assert {:error, %Failure{kind: :not_found}} = Button.find("<button>Save</button>", "button", "Delete")
  end
end
