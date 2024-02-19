defmodule PhoenixTest.Query do
  @moduledoc """
  Module for querying HTML content and extracting elements based on CSS selectors and text content.
  """

  alias PhoenixTest.Html

  @doc """
  Finds the first element in the HTML content with the specified CSS selector.

  ## Parameters

  - `html`: The HTML content to search within.
  - `selector`: The CSS selector for the element.

  ## Returns

  - `element`: If a the element is found.

  ## Raises

  Raises `ArgumentError` if no element is found with the given selector or if multiple elements are found.
  """
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

  @doc """
  Finds the first element in the HTML content with the specified CSS selector and text.

  ## Parameters

  - `html`: The HTML content to search within.
  - `selector`: The CSS selector for the element.
  - `text`: The text for the element.

  ## Returns

  - `element`: If a the element is found.

  ## Raises

  Raises `ArgumentError` if no element is found with the given selector or if multiple elements are found.
  """
  def find!(html, selector, text) do
    case find(html, selector, text) do
      {:not_found, elements} ->
        msg =
          if Enum.any?(elements) do
            """
            Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

            The following elements matching the selector were found:

            #{Enum.map_join(elements, "\n", &Html.raw/1)}
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

  @doc """
  Finds the first element in the HTML content with the specified CSS selector.

  ## Parameters

  - `html`: The HTML content to search within.
  - `selector`: The CSS selector for the element.
  - `text`: The text for the element.

  ## Returns

  - `{:found, element}`: If a single element is found.
  - `:not_found`: If no elements are found.
  - `{:found_many, elements}`: If more than one element is found.
  """
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

  @doc """
  Finds the first element in the HTML content with the specified CSS selector and text.

  ## Parameters

  - `html`: The HTML content to search within.
  - `selector`: The CSS selector for the element.

  ## Returns

  - `{:found, element}`: If a single element is found.
  - `{:not_found, elements_matched_selector}`: If no elements are found.
  - `{:found_many, elements}`: If more than one element is found.
  """
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

  @doc """
  Finds one element from the given list of selectors in the HTML content, raising an error if not found.

  ## Parameters

  - `html`: The HTML content to search within.
  - `elements`: A list of tuples where each tuple contains a CSS selector and optional text content.

  ## Returns

  - `found_element`: The found element.
  - `found_element`: In case a list of possible matches, returns the first one.

  ## Raises

  Raises `ArgumentError` if no element is found with the given selectors or if multiple elements are found.
  """
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

  @doc """
  Finds one element from the given list of selectors in the HTML content.

  ## Parameters

  - `html`: The HTML content to search within.
  - `elements`: A list of tuples where each tuple contains a CSS selector and optional text content.

  ## Returns

  - `found`: If a single element is found.
  - `found`: If a many elements are found.
  - `{:not_found, potential_matches}`: If no elements match the content criteria but elements match the selector.
  """
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
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_find_one_of_elements_for_error(selectors_and_text) do
    Enum.map_join(selectors_and_text, "\n", fn
      {selector, text} ->
        "- #{inspect(selector)} with content #{inspect(text)}"

      selector ->
        "- #{inspect(selector)}"
    end)
  end
end
