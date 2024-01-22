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
        msg = """
          Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

          Elements with given selector found: #{inspect(Enum.map(elements, &Floki.text/1) |> Enum.join(", "))}
        """

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
          expected to find one of these elements but found none

        #{Enum.map_join(elements, " or \n", &inspect(&1))}
        """

      found_element ->
        found_element
    end
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
