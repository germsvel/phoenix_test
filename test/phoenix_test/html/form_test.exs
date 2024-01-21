defmodule PhoenixTest.Html.FormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html

  describe "parse/1" do
    test "parses a form's inputs" do
      data =
        form_data("""
          <form id="user-form" action="/" method="post">
            <label name="email">Email</label>
            <input type="text" name="email" value="Aragorn" />
          </form>
        """)

      %{"inputs" => [input]} = Html.Form.parse(data)

      assert %{"name" => "email", "type" => "text", "value" => "Aragorn"} = input
    end
  end

  defp form_data(html_form) do
    html_form
    |> Html.parse()
    |> Html.find("form")
  end
end
