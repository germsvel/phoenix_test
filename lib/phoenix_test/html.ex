defmodule PhoenixTest.Html do
  @moduledoc false
  def parse(html) do
    html
    |> Floki.parse_document!()
  end

  def text_content(element), do: Floki.text(element) |> String.trim()

  def attribute(element, attr) do
    element
    |> Floki.attribute(attr)
    |> List.first()
  end

  def find(html, selector, text) do
    elements =
      html
      |> all(selector)

    elements
    |> Enum.find(:not_found, fn element ->
      Floki.text(element) =~ text
    end)
    |> case do
      :not_found ->
        msg =
          if Enum.any?(elements) do
            """
              Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

              The following elements with given selector were found:

              - #{Enum.map(elements, &Floki.text/1) |> Enum.join("\n  - ")}
            """
          else
            """
              Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.
            """
          end

        raise ArgumentError, msg

      element ->
        element
    end
  end

  def find(html, selector) do
    case Floki.find(html, selector) do
      [] ->
        raise ArgumentError, "Could not find element with selector #{inspect(selector)}"

      [element] ->
        element

      [_, _ | _rest] ->
        raise ArgumentError, "Found more than one element with selector #{inspect(selector)}"
    end
  end

  def find_submit_buttons(html, selector, text) do
    html
    |> parse()
    |> find_one_of(["input[type=submit][value=#{text}]", {selector, text}])
  end

  def find_one_of(html, elements) do
    elements
    |> Enum.map(fn
      {selector, text} ->
        find_with_text(html, selector, text)

      selector ->
        find_first(html, selector)
    end)
    |> Enum.find(fn result ->
      result != nil
    end)
    |> case do
      nil ->
        raise ArgumentError, """
        Could not find an element with given selector.

        I was looking for an element with one of these selectors:

        #{format_find_one_of_elements_for_error(elements)}
        """

      found_element ->
        found_element
    end
  end

  defp format_find_one_of_elements_for_error(elements) do
    Enum.map_join(elements, "\n", fn
      {selector, text} ->
        "Selector #{selector} and text #{text}"

      element ->
        inspect(element)
    end)
  end

  defp find_with_text(html, selector, text) do
    elements =
      html
      |> all(selector)

    Enum.find(elements, fn element ->
      Floki.text(element) =~ text
    end)
  end

  defp find_first(html, selector) do
    html
    |> all(selector)
    |> List.first()
  end

  def all(html, selector) do
    Floki.find(html, selector)
  end
end
