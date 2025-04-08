defmodule PhoenixTest.FormPayloadTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormPayload

  describe "new" do
    test "transforms FormData into a map ready to be a form payload" do
      html = """
      <form id="form">
        <input type="hidden" name="method" value="delete"/>
        <input name="input" value="value" />

        <input type="text" name="text-input" value="text value" />
        <input type="number" name="number-input" value="123" />

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

      assert %{
               "method" => "delete",
               "input" => "value",
               "text-input" => "text value",
               "number-input" => "123",
               "select" => "selected",
               "select_multiple" => ["select_1", "select_2"],
               "checkbox" => "checked",
               "radio" => "checked",
               "textarea" => "Default text"
             } = FormPayload.new(form.form_data)
    end

    test "multiple checkbox values named with [] resolve to a list" do
      html = """
      <form id="form">
        <input name="checkbox[]" type="checkbox" value="some_value" checked />
        <input name="checkbox[]" type="checkbox" value="another_value" checked />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => ["another_value", "some_value"]} = FormPayload.new(form.form_data)
    end

    test "single checkboxe value named with [] resolves to a list" do
      html = """
      <form id="form">
        <input name="checkbox[]" type="checkbox" value="some_value" checked />
        <input name="checkbox[]" type="checkbox" value="another_value" />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => ["some_value"]} = FormPayload.new(form.form_data)
    end

    test "multiple hidden inputs named with [] resolve to a list" do
      html = """
      <form id="form">
        <input name="hidden[]" type="hidden" value="some_value" />
        <input name="hidden[]" type="hidden" value="another_value" />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"hidden" => ["another_value", "some_value"]} = FormPayload.new(form.form_data)
    end

    test "single hidden input value named with [] resolves to a list" do
      html = """
      <form id="form">
        <input name="hidden[]" type="hidden" value="some_value" />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"hidden" => ["some_value"]} = FormPayload.new(form.form_data)
    end

    test "ignores hidden value for checkbox when checked" do
      html = """
      <form id="form">
        <input name="checkbox" type="hidden" value="unchecked" />
        <input name="checkbox" type="checkbox" value="checked" checked />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => "checked"} = FormPayload.new(form.form_data)
    end

    test "uses hidden value for checkbox when unchecked" do
      html = """
      <form id="form">
        <input name="checkbox" type="hidden" value="unchecked" />
        <input name="checkbox" type="checkbox" value="checked" />
      </form>
      """

      form = Form.find!(html, "form")

      assert %{"checkbox" => "unchecked"} = FormPayload.new(form.form_data)
    end
  end

  describe "add_form_data" do
    test "adds new top-level data" do
      payload = %{"name" => "Frodo"}
      uploads = [{"avatar", upload()}]

      new_payload = FormPayload.add_form_data(payload, uploads)

      assert new_payload == %{"name" => "Frodo", "avatar" => upload()}
    end

    test "overwrites existing field value" do
      payload = %{"avatar" => "how did this string get here?"}
      uploads = [{"avatar", upload()}]

      updated_payload = FormPayload.add_form_data(payload, uploads)

      assert updated_payload == %{"avatar" => upload()}
    end

    test "injects nested data" do
      payload = %{"user" => %{"name" => "Frodo"}}
      uploads = [{"user[avatar]", upload()}]

      updated_payload = FormPayload.add_form_data(payload, uploads)

      assert updated_payload == %{"user" => %{"name" => "Frodo", "avatar" => upload()}}
    end

    test "handles form data in list" do
      payload = %{}
      uploads = [{"avatar[]", upload(0)}, {"avatar[]", upload(1)}]

      updated_payload = FormPayload.add_form_data(payload, uploads)

      assert updated_payload == %{"avatar" => [upload(0), upload(1)]}
    end

    test "handles all data in inputs_for pseudo list" do
      payload = %{}
      uploads = [{"avatar[0][file]", upload(0)}, {"avatar[1][file]", upload(1)}]

      updated_payload = FormPayload.add_form_data(payload, uploads)

      assert updated_payload == %{"avatar" => %{"0" => %{"file" => upload(0)}, "1" => %{"file" => upload(1)}}}
    end

    defp upload(filename \\ 0), do: %Plug.Upload{filename: filename}
  end
end
