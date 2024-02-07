defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias PhoenixTest.Query

  def assert_has(session, selector, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector, text)
    |> case do
      {:found, _found} ->
        assert true

      {:not_found, []} ->
        raise """
        Could not find any elements with selector #{inspect(selector)}.
        """

      {:not_found, elements_matched_selector} ->
        raise """
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
        raise """
        Expected not to find an element.

        But found an element with selector #{inspect(selector)} and text #{inspect(text)}:

        #{format_found_element(element)}
        """

      {:found_many, elements} ->
        raise """
        Expected not to find an element.

        But found #{Enum.count(elements)} elements with selector #{inspect(selector)} and text #{inspect(text)}:
        """
    end

    session
  end

  defp format_found_elements(elements) do
    Enum.map_join(elements, "\n", &format_found_element/1)
  end

  defp format_found_element({tag, _attrs, [content]}) do
    "<#{tag}> with content \"#{Floki.raw_html(content)}\""
  end

  defp format_found_element({tag, _attrs, content}) when is_list(content) do
    "<#{tag}> with content:\n#{Floki.raw_html(content, pretty: true)}"
  end
end
