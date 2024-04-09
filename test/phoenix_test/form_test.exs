defmodule PhoenixTest.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Button
  alias PhoenixTest.Form

  describe "find_by_descendant!" do
    test "returns form ID as selector if id is present" do
      html = """
      <form id="user-form">
        <button>Save</save>
      </form>
      """

      button = %Button{selector: "button", text: "Save"}

      form = Form.find_by_descendant!(html, button)

      assert form.selector == "#user-form"
    end

    test "creates composite of form's attributes for selector if id isn't present" do
      html = """
      <form action="/" method="post" class="form">
        <button>Save</save>
      </form>
      """

      button = %Button{selector: "button", text: "Save"}

      form = Form.find_by_descendant!(html, button)

      assert form.selector == ~s(form[action="/"][method="post"][class="form"])
    end
  end
end
