defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def assert_has(session, selector, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector, text)
    |> case do
      {:found, _found} ->
        assert true

      {:found_many, _found} ->
        assert true

      {:not_found, []} ->
        raise AssertionError,
          message: """
          Could not find any elements with selector #{inspect(selector)}.
          """

      {:not_found, elements_matched_selector} ->
        raise AssertionError,
          message: """
          Could not find element with text #{inspect(text)}.

          Found other elements matching the selector #{inspect(selector)}:

          #{format_found_elements(elements_matched_selector)}
          """
    end

    session
  end

  def refute_has(session, selector, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector, text)
    |> case do
      {:not_found, _} ->
        refute false

      {:found, element} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found an element with selector #{inspect(selector)} and text #{inspect(text)}:

          #{format_found_elements(element)}
          """

      {:found_many, elements} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found #{Enum.count(elements)} elements with selector #{inspect(selector)} and text #{inspect(text)}:
          """
    end

    session
  end

  defp format_found_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_found_elements(element), do: format_found_elements([element])
end
