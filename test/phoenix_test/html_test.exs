defmodule PhoenixTest.HtmlTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html

  describe "element_text" do
    test "extracts text from parsed html, removing extra whitespace" do
      html = """
      <label>
        hello
        <em>world!</em>
      </label>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "hello world!"
    end

    test "extracts the text from the top level element, but includes known text elements)" do
      html = """
      <div>
        hello
        <a href="/">elixir</a>
        <span>and</span>
        <small>phoenix</small>
        <em>world!</em>

        <label>excluded text</label>
        <form>also excluded</form>
        <textarea>also excluded</textarea>
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "hello elixir and phoenix world!"
    end

    test "extracts text but excludes select elements and their options" do
      html = """
      <div>
        <p>Choose an option:</p>
        <select>
          <option value="1">First option</option>
          <option value="2">Second option</option>
        </select>
        <p>More text here</p>
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Choose an option: More text here"
    end

    test "extracts text from label but excludes textarea value" do
      html = """
      <label for="wrapped-notes">
        Wrapped notes

        <textarea name="wrapped-notes" rows="5" cols="33">
          Prefilled wrapped notes
        </textarea>
      </label>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Wrapped notes"
    end

    test "includes textarea text if it's the top-level element" do
      html = """
      <textarea name="wrapped-notes" rows="5" cols="33">
        Prefilled notes
      </textarea>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Prefilled notes"
    end
  end
end
