defmodule PhoenixTest.HtmlTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html

  describe "text" do
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
        |> Html.text()

      assert result == "hello world!"
    end
  end
end
