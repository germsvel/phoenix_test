defmodule PhoenixTest.Query do
  @moduledoc false

  alias PhoenixTest.Html

  def find!(html, selector) do
    case find(html, selector) do
      :not_found ->
        raise ArgumentError, "Could not find element with selector #{inspect(selector)}"

      {:found, element} ->
        element

      {:found_many, _elements} ->
        raise ArgumentError, "Found more than one element with selector #{inspect(selector)}"
    end
  end

  def find!(html, selector, text) do
    case find(html, selector, text) do
      {:not_found, elements} ->
        msg =
          if Enum.any?(elements) do
            """
              Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

              The following elements with given selector were found:

              - #{Enum.map(elements, &Html.text/1) |> Enum.join("\n  - ")}
            """
          else
            """
              Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.
            """
          end

        raise ArgumentError, msg

      {:found, element} ->
        element
    end
  end

  def find(html, selector) do
    html
    |> Html.parse()
    |> Html.all(selector)
    |> case do
      [] ->
        :not_found

      [element] ->
        {:found, element}

      [_, _ | _rest] = elements ->
        {:found_many, elements}
    end
  end

  def find(html, selector, text) do
    html
    |> Html.parse()
    |> find_with_text(selector, text)
  end

  def find_submit_buttons(html, selector, text) do
    elements = ["input[type=submit][value=#{text}]", {selector, text}]

    html
    |> Html.parse()
    |> find_one_of(elements)
    |> case do
      {:not_found, elements} ->
        raise ArgumentError, """
        Could not find an element with given selector.

        I was looking for an element with one of these selectors:

        #{format_find_one_of_elements_for_error(elements)}
        """

      {:found, found_element} ->
        found_element
    end
  end

  defp find_with_text(html, selector, text) do
    elements =
      html
      |> Html.all(selector)

    Enum.find(elements, :not_found, fn element ->
      Html.text(element) =~ text
    end)
    |> then(fn
      :not_found -> {:not_found, elements}
      found -> {:found, found}
    end)
  end

  defp find_one_of(html, elements) do
    elements
    |> Enum.map(fn
      {selector, text} ->
        find_with_text(html, selector, text)

      selector ->
        first(html, selector)
    end)
    |> Enum.find({:not_found, elements}, fn
      {:not_found, _} -> false
      {:found, _} -> true
    end)
  end

  defp first(html, selector) do
    html
    |> Html.all(selector)
    |> List.first({:not_found, selector})
  end

  defp format_find_one_of_elements_for_error(elements) do
    Enum.map_join(elements, "\n", fn
      {selector, text} ->
        "Selector #{selector} and text #{text}"

      element ->
        inspect(element)
    end)
  end
end
