defmodule PhoenixTest.Element.ButtonTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element.Button

  describe "find!" do
    test "finds button by selector and text" do
      html = """
      <button id="save">
        Save
      </button>

      <button id="delete">
        Delete
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.id == "save"
    end

    test "raises an error if no button is found" do
      html = """
      <button id="save">
        Save
      </button>
      """

      assert_raise ArgumentError, fn ->
        Button.find!(html, "button", "Delete")
      end
    end
  end

  describe "find_first_submit" do
    test "does not find button type buttons" do
      html = """
      <button type="button">
        Add Field
      </button>
      <button type="submit">
        Save
      </button>
      """

      button = Button.find_first_submit(html)

      assert button.type == "submit"
    end
  end

  describe "button.selector" do
    test "returns a dom id if an id is found" do
      html = """
      <button id="save">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.selector == ~s|[id="save"]|
    end

    test "returns a composite selector if button has no id" do
      html = """
      <button name="super" value="button">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.selector == ~s(button[name="super"][value="button"])
    end

    test "keeps provided selector if more complex than 'button'" do
      html = """
        <div id="button-id">
          <button>Save</button>
        </div>
      """

      button = Button.find!(html, "#button-id button", "Save")

      assert button.selector == ~s(#button-id button)
    end
  end

  describe "button.form_id" do
    test "returns the button's form attribute if present" do
      html = """
      <button form="form-id">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.form_id == "form-id"
    end

    test "returns nil if button doesn't have a form attribute" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.form_id == nil
    end
  end

  describe "button.name and button.value" do
    test "returns button's name and value if present" do
      html = """
      <button name="super" value="save">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.name == "super"
      assert button.value == "save"
    end

    test "returns nil if name and value aren't found" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert is_nil(button.name)
      assert is_nil(button.value)
    end

    test "returns empty value if name is present and no value is found" do
      html = """
      <button name="generate">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.name == "generate"
      assert button.value == ""
    end
  end

  describe "button.type" do
    test "returns button's type if present" do
      html = """
      <button type="button">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.type == "button"
    end

    test "returns 'submit' if the button has no type attribute" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert button.type == "submit"
    end
  end

  describe "belongs_to_form?" do
    test "returns true if button has a form ancestor" do
      html = """
      <form>
        <button>
          Save
        </button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.belongs_to_form?(button, html)
    end

    test "returns true if button has type='button'" do
      html = """
      <form>
        <button type="button">
          Save
        </button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.belongs_to_form?(button, html)
    end

    test "returns true if button has a form attribute" do
      html = """
      <button form="form-id">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.belongs_to_form?(button, html)
    end

    test "returns false if button stands alone" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      refute Button.belongs_to_form?(button, html)
    end
  end

  describe "submits_form?" do
    test "returns true if associated and type is submit" do
      html = """
      <form>
        <button>
          Save
        </button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.submits_form?(button, html)
    end

    test "returns true for external submit button with form attribute" do
      html = """
      <button form="form-id">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.submits_form?(button, html)
    end

    test "returns false if associated but type='button'" do
      html = """
      <form>
        <button type="button">
          Save
        </button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      refute Button.submits_form?(button, html)
    end

    test "returns false if button stands alone" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      refute Button.submits_form?(button, html)
    end
  end

  describe "phx_click?" do
    test "returns true if button has a phx-click attribute" do
      html = """
      <button phx-click="save">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.phx_click?(button)
    end

    test "returns false if button doesn't have a phx-click attribute" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      refute Button.phx_click?(button)
    end
  end

  describe "has_data_method?" do
    test "returns true if button has a data-method attribute" do
      html = """
      <button data-method="put">
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      assert Button.has_data_method?(button)
    end

    test "returns false if button doesn't have a data-method attribute" do
      html = """
      <button>
        Save
      </button>
      """

      button = Button.find!(html, "button", "Save")

      refute Button.has_data_method?(button)
    end
  end

  describe "parent_form!" do
    test "returns the ancestor form from html" do
      html = """
      <form id="form">
        <button>
          Save
        </button>
      </form>
      """

      form =
        html
        |> Button.find!("button", "Save")
        |> Button.parent_form!(html)

      assert form.id == "form"
    end

    test "returns associated form if button has form attribute" do
      html = """
      <form id="form">
      </form>
      <button form="form">
        Save
      </button>
      """

      form =
        html
        |> Button.find!("button", "Save")
        |> Button.parent_form!(html)

      assert form.id == "form"
    end

    test "raises an error if no parent form is found" do
      html = """
        <button>
          Save
        </button>
      """

      button =
        Button.find!(html, "button", "Save")

      assert_raise ArgumentError, fn ->
        Button.parent_form!(button, html)
      end
    end
  end
end
