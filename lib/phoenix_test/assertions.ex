defmodule PhoenixTest.Assertions do
  import ExUnit.Assertions

  alias PhoenixTest.Html

  def assert_has(conn, css, text) do
    found =
      conn
      |> PhoenixTest.Driver.render_html()
      |> Html.parse()
      |> Html.find(css)
      |> Html.text_content()

    if found == text do
      assert true
    else
      raise "Expected to find #{inspect(text)} but found #{inspect(found)} instead"
    end

    conn
  end

  def refute_has(conn, css, text) do
    conn
    |> PhoenixTest.Driver.render_html()
    |> Html.parse()
    |> Html.all(css)
    |> case do
      [] ->
        refute false

      elements ->
        if Enum.any?(elements, &element_with_text?(&1, text)) do
          raise "Found element with selector #{inspect(css)} and text #{inspect(text)} when should not be present"
        else
          refute false
        end
    end
  end

  defp element_with_text?(el, text) do
    Html.text_content(el) == text
  end
end
