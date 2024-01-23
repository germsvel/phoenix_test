defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias PhoenixTest.Html

  def assert_has(session, css, text) do
    found =
      session
      |> PhoenixTest.Driver.render_html()
      |> Html.parse()
      |> Html.find(css, text)
      |> Html.text_content()

    if found =~ text do
      assert true
    else
      raise """
      Expected to find #{inspect(text)} somewhere in here:

      #{found}
      """
    end

    session
  end

  def refute_has(session, css, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Html.parse()
    |> Html.all(css)
    |> case do
      [] ->
        refute false

      elements ->
        if Enum.any?(elements, &element_with_text?(&1, text)) do
          raise """
          Expected not to find an element.

          But found an element with selector #{inspect(css)} and text #{inspect(text)}.
          """
        else
          refute false
        end
    end
  end

  defp element_with_text?(el, text) do
    Html.text_content(el) == text
  end
end
