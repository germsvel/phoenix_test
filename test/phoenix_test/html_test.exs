defmodule PhoenixTest.HtmlTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html

  describe "inner_text" do
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
        |> Html.inner_text()

      assert result == "hello world!"
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
        |> Html.inner_text()

      assert result == "Choose an option: More text here"
    end
  end
end
