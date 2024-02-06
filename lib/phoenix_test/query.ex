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

      {:found_many, _elements} ->
        msg =
          """
          Found more than one element with selector #{inspect(selector)} and text #{inspect(text)}.
          """

        raise ArgumentError, msg
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

      [_ | _] = elements ->
        {:found_many, elements}
    end
  end

  def find(html, selector, text) do
    elements_matched_selector =
      html
      |> Html.parse()
      |> Html.all(selector)

    elements_matched_selector
    |> Enum.filter(fn element -> Html.text(element) =~ text end)
    |> case do
      [] -> {:not_found, elements_matched_selector}
      [found] -> {:found, found}
      [_ | _] = found_many -> {:found_many, found_many}
    end
  end

  def find_submit_buttons(html, selector, text) do
    elements = ["input[type=submit][value=#{text}]", {selector, text}]

    find_one_of!(html, elements)
  end

  def find_one_of!(html, elements) do
    html
    |> find_one_of(elements)
    |> case do
      {:not_found, []} ->
        raise ArgumentError, """
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors:

        #{format_find_one_of_elements_for_error(elements)}
        """

      {:not_found, potential_matches} ->
        raise ArgumentError, """
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors:

        #{format_find_one_of_elements_for_error(elements)}

        I found some elements that match the selector but not the content:

        #{format_potential_matches(potential_matches)}
        """

      {:found, found_element} ->
        found_element

      {:found_many, [found_element | _]} ->
        found_element
    end
  end

  def find_one_of(html, elements) do
    results =
      elements
      |> Enum.map(fn
        {selector, text} ->
          find(html, selector, text)

        selector ->
          find(html, selector)
      end)

    Enum.find(results, :not_found, fn
      :not_found -> false
      {:not_found, _} -> false
      {:found, _} -> true
      {:found_many, _} -> true
    end)
    |> case do
      {:found, _} = found -> found
      {:found_many, _} = found -> found
      :not_found -> {:not_found, potential_matches(results)}
    end
  end

  defp potential_matches(results) do
    results
    |> Enum.filter(fn
      {:not_found, _} -> true
      _ -> false
    end)
    |> Enum.reduce([], fn {:not_found, values}, acc ->
      values ++ acc
    end)
  end

  defp format_potential_matches(elements) do
    Enum.map_join(elements, "\n", fn
      {tag, _, [content]} -> "<#{tag}> tag with content #{inspect(content)}"
    end)
  end

  defp format_find_one_of_elements_for_error(selectors_and_text) do
    Enum.map_join(selectors_and_text, "\n", fn
      {selector, text} ->
        "Selector #{inspect(selector)} with content #{inspect(text)}"

      selector ->
        "Selector #{inspect(selector)}"
    end)
  end
end
