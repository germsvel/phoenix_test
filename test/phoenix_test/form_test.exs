defmodule PhoenixTest.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Button
  alias PhoenixTest.Field
  alias PhoenixTest.Form

  describe "find!" do
    test "returns form ID as selector if id is present" do
      html = """
      <form id="user-form">
      </form>
      """

      form = Form.find!(html, "#user-form")

      assert form.selector == "#user-form"
    end

    test "creates composite selector of form's attributes (ignoring classes) if id isn't present" do
      html = """
      <form action="/" method="post" class="mx-auto text-3xl">
      </form>
      """

      form = Form.find!(html, "form")

      assert form.selector == ~s(form[action="/"][method="post"])
    end

    test "generates default form data from form's html" do
      html = """
      <form id="form">
        <input type="hidden" name="method" value="delete"/>
        <input name="input" value="value" />

        <input type="text" name="text-input" value="text value" />

        <select name="select">
          <option value="not_selected">Not selected</option>
          <option value="selected" selected>Selected</option>
        </select>

        <select name="select_none_selected">
          <option value="first">Selected by default</option>
        </select>

        <input name="checkbox" type="checkbox" value="not_checked" />
        <input name="checkbox" type="checkbox" value="checked" checked />

        <input name="radio" type="radio" value="not_checked" />
        <input name="radio" type="radio" value="checked" checked />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{
               "method" => "delete",
               "input" => "value",
               "text-input" => "text value",
               "select" => "selected",
               "checkbox" => "checked",
               "radio" => "checked"
             } = form.form_data
    end

    test "does not include disabled inputs in form_data" do
      html = """
      <form id="form">
        <input name="input" value="value" disabled />
        <input name="checkbox" type="checkbox" value="checked" checked disabled />
        <input name="radio" type="radio" value="checked" checked disabled />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{} == form.form_data
    end

    test "ignores hidden value for checkbox when checked" do
      html = """
      <form id="form">
        <input name="checkbox" type="hidden" value="unchecked" />
        <input name="checkbox" type="checkbox" value="checked" checked />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => "checked"} = form.form_data
    end

    test "uses hidden value for checkbox when unchecked" do
      html = """
      <form id="form">
        <input name="checkbox" type="hidden" value="unchecked" />
        <input name="checkbox" type="checkbox" value="checked" />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => "unchecked"} = form.form_data
    end

    test "submit_button returns the only button in the form" do
      html = """
      <form id="form">
        <button type="submit">Save</button>
      </form>
      """

      form = Form.find!(html, "form")

      assert %Button{text: "Save"} = form.submit_button
    end

    test "submit_button returns the first button in the form (if many)" do
      html = """
      <form id="form">
        <button type="submit">Save</button>
        <button>Cancel"</button>
      </form>
      """

      form = Form.find!(html, "form")

      assert %Button{text: "Save"} = form.submit_button
    end

    test "submit_button returns nil if no buttons in the form" do
      html = """
      <form id="form">
      </form>
      """

      form = Form.find!(html, "form")

      assert is_nil(form.submit_button)
    end
  end

  describe "find_by_descendant!" do
    test "finds form for button (if form id is present)" do
      html = """
      <form id="user-form">
        <button>Save</save>
      </form>
      """

      button = %Button{selector: "button", text: "Save"}

      form = Form.find_by_descendant!(html, button)

      assert form.selector == "#user-form"
    end

    test "creates composite selector of form's attributes (ignoring classes) if id isn't present" do
      html = """
      <form action="/" method="post" class="mx-auto text-3xl">
        <button>Save</save>
      </form>
      """

      button = %Button{selector: "button", text: "Save"}

      form = Form.find_by_descendant!(html, button)

      assert form.selector == ~s(form[action="/"][method="post"])
    end

    test "finds parent form for fields" do
      html = """
      <form id="user-form">
        <label>
          Email
          <input type="text" name="email" />
        </label>
      </form>
      """

      field = Field.find_input!(html, "Email")

      form = Form.find_by_descendant!(html, field)

      assert form.selector == "#user-form"
    end
  end
end
