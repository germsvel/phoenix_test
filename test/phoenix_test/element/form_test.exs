defmodule PhoenixTest.Element.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html

  describe "find!" do
    test "finds a form by selector" do
      html = """
      <form id="user-form">
      </form>

      <form id="other-form">
      </form>
      """

      form = Form.find!(html, "#user-form")

      assert form.id == "user-form"
    end
  end

  describe "find_by_descendant!" do
    test "finds parent form for button (if form id is present)" do
      html = """
      <form id="user-form">
        <button>Save</save>
      </form>
      """

      button = %Button{selector: "button", text: "Save"}

      form = Form.find_by_descendant!(html, button)

      assert form.selector == ~s|[id="user-form"]|
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

      field = Field.find_input!(html, "input", "Email", exact: true)

      form = Form.find_by_descendant!(html, field)

      assert form.selector == ~s|[id="user-form"]|
    end

    test "creates same form as `find!`" do
      html = """
      <form id="user-form">
        <label>
          Email
          <input type="text" name="email" />
        </label>
      </form>
      """

      field = Field.find_input!(html, "input", "Email", exact: true)

      input_form = Form.find_by_descendant!(html, field)
      find_form = Form.find!(html, "#user-form")

      assert %{input_form | parsed: nil} == %{find_form | parsed: nil}

      assert Html.element(input_form.parsed) == Html.element(find_form.parsed)
    end
  end

  describe "form.selector" do
    test "form's selector is id if id is present" do
      html = """
      <form id="user-form">
      </form>
      """

      form = Form.find!(html, "#user-form")

      assert form.selector == ~s|[id="user-form"]|
    end

    test "creates composite selector of form's attributes (ignoring classes) if id isn't present" do
      html = """
      <form action="/" method="post" class="mx-auto text-3xl">
      </form>
      """

      form = Form.find!(html, "form")

      assert form.selector == ~s(form[action="/"][method="post"])
    end
  end

  describe "form.form_data" do
    alias PhoenixTest.FormData

    test "generates default form data from form's html" do
      html = """
      <form id="form">
        <input type="hidden" name="method" value="delete"/>
        <input name="input" value="value" />

        <input type="date" name="date-input" value="date value" />
        <input type="datetime-local" name="datetime-local-input" value="datetime-local value" />
        <input type="email" name="email-input" value="test@example.com" />
        <input type="month" name="month-input" value="month value" />
        <input type="number" name="number-input" value="123" />
        <input type="password" name="password-input" value="password value" />
        <input type="range" name="range-input" value="range value" />
        <input type="search" name="search-input" value="search value" />
        <input type="tel" name="tel-input" value="tel value" />
        <input type="text" name="text-input" value="text value" />
        <input type="time" name="time-input" value="time value" />
        <input type="url" name="url-input" value="url value" />
        <input type="week" name="week-input" value="week value" />

        <select name="select">
          <option value="not_selected">Not selected</option>
          <option value="selected" selected>Selected</option>
        </select>

        <select multiple name="select_multiple[]">
          <option value="select_1" selected>Selected 1</option>
          <option value="select_2" selected>Selected 2</option>
          <option value="select_3">Not Selected</option>
        </select>

        <select name="select_none_selected">
          <option value="first">Selected by default</option>
        </select>

        <input name="checkbox" type="checkbox" value="not_checked" />
        <input name="checkbox" type="checkbox" value="checked" checked />

        <input name="radio" type="radio" value="not_checked" />
        <input name="radio" type="radio" value="checked" checked />

        <textarea name="textarea">
          Default text
        </textarea>
      </form>
      """

      form = Form.find!(html, "form")
      form_data = form.form_data

      assert FormData.has_data?(form_data, "method", "delete")
      assert FormData.has_data?(form_data, "input", "value")
      assert FormData.has_data?(form_data, "date-input", "date value")
      assert FormData.has_data?(form_data, "datetime-local-input", "datetime-local value")
      assert FormData.has_data?(form_data, "email-input", "test@example.com")
      assert FormData.has_data?(form_data, "month-input", "month value")
      assert FormData.has_data?(form_data, "number-input", "123")
      assert FormData.has_data?(form_data, "password-input", "password value")
      assert FormData.has_data?(form_data, "range-input", "range value")
      assert FormData.has_data?(form_data, "search-input", "search value")
      assert FormData.has_data?(form_data, "tel-input", "tel value")
      assert FormData.has_data?(form_data, "text-input", "text value")
      assert FormData.has_data?(form_data, "time-input", "time value")
      assert FormData.has_data?(form_data, "url-input", "url value")
      assert FormData.has_data?(form_data, "week-input", "week value")
      assert FormData.has_data?(form_data, "select", "selected")
      assert FormData.has_data?(form_data, "select_multiple[]", "select_1")
      assert FormData.has_data?(form_data, "select_multiple[]", "select_2")
      assert FormData.has_data?(form_data, "checkbox", "checked")
      assert FormData.has_data?(form_data, "radio", "checked")
      assert FormData.has_data?(form_data, "textarea", "Default text")
    end

    test "does not include disabled inputs in form_data" do
      html = """
      <form id="form">
        <input name="input" value="value" disabled />
        <input name="checkbox" type="checkbox" value="checked" checked disabled />
        <input name="radio" type="radio" value="checked" checked disabled />
        <textarea name="textarea" disabled>Disabled value</textarea>
      </form>
      """

      form = Form.find!(html, "form")

      refute FormData.has_data?(form.form_data, "input", "value")
    end

    test "does not include inputs without a `name` attribute" do
      html = """
      <form id="form">
        <label>
          Ignored presentational input <input value="123" />
        </label>
      </form>
      """

      form = Form.find!(html, "form")

      assert FormData.empty?(form.form_data)
    end

    test "does not include select elements that have no options or no selected options" do
      html = """
      <form id="form">
        <select name="pets">
        </select>

        <select multiple name="select_multiple[]">
          <option value="select_1">selection 1</option>
          <option value="select_2">selection 2</option>
        </select>
      </form>
      """

      form = Form.find!(html, "form")

      assert FormData.empty?(form.form_data)
    end

    test "includes hidden inputs" do
      html = """
      <form id="form">
        <input name="checkbox" type="hidden" value="unchecked" />
      </form>
      """

      form = Form.find!(html, "form")

      assert FormData.has_data?(form.form_data, "checkbox", "unchecked")
    end

    test "includes checked inputs" do
      html = """
      <form id="form">
        <input name="checkbox" type="checkbox" value="checked" checked />
      </form>
      """

      form = Form.find!(html, "form")

      assert FormData.has_data?(form.form_data, "checkbox", "checked")
    end
  end

  describe "form.submit_button" do
    test "returns the only button in the form" do
      html = """
      <form id="form">
        <button type="submit">Save</button>
      </form>
      """

      form = Form.find!(html, "form")

      assert %Button{text: "Save"} = form.submit_button
    end

    test "returns the first button in the form (if many)" do
      html = """
      <form id="form">
        <button type="submit">Save</button>
        <button>Cancel"</button>
      </form>
      """

      form = Form.find!(html, "form")

      assert %Button{text: "Save"} = form.submit_button
    end

    test "returns nil if no buttons in the form" do
      html = """
      <form id="form">
      </form>
      """

      form = Form.find!(html, "form")

      assert is_nil(form.submit_button)
    end
  end

  describe "form.action" do
    test "returns action if found in form" do
      html = """
      <form id="form" action="/">
      </form>
      """

      form = Form.find!(html, "form")

      assert form.action == "/"
    end

    test "returns nil if no action is found" do
      html = """
      <form id="form">
      </form>
      """

      form = Form.find!(html, "form")

      assert is_nil(form.action)
    end
  end

  describe "form.method" do
    test "sets 'get' as the form's method if none is specified" do
      html = """
      <form id="user-form">
      </form>
      """

      form = Form.find!(html, "form")

      assert form.method == "get"
    end

    test "sets form method as operative_method if present" do
      html = """
      <form id="user-form" action="/" method="post">
      </form>
      """

      form = Form.find!(html, "form")

      assert form.method == "post"
    end

    test "sets method based on hidden input if available" do
      html =
        """
        <form id="user-form" action="/" method="post">
          <input type="hidden" name="_method" value="put"/>
        </form>
        """

      form = Form.find!(html, "form")

      assert form.method == "put"
    end
  end

  describe "form_element_names/1" do
    test "returns list of names for all inputs, selects, texareas, etc." do
      html = """
      <form>
        <input type="hidden" name="method" value="delete"/>
        <input name="some_input" value="value" />
        <select name="some_select">
          <option value="a">A</option>
          <option value="b" selected>B</option>
        </select>

        <select multiple name="select_multiple[]">
          <option value="select_1" selected>Selected 1</option>
          <option value="select_2" selected>Selected 2</option>
          <option value="select_3">Not Selected</option>
        </select>

        <input name="some_checkbox" type="checkbox" value="not_checked" />
        <input name="some_checkbox" type="checkbox" value="checked" checked />

        <input name="some_radio" type="radio" value="not_checked" />
        <input name="some_radio" type="radio" value="checked" checked />

        <textarea name="some_textarea">
          Default text
        </textarea>
      </form>
      """

      form = Form.find!(html, "form")
      names = Form.form_element_names(form)

      assert "method" in names
      assert "some_input" in names
      assert "some_select" in names
      assert "select_multiple[]" in names
      assert "some_checkbox" in names
      assert "some_radio" in names
      assert "some_textarea" in names
    end
  end
end
