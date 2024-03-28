defmodule PhoenixTest.Query do
  @moduledoc false

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
  def find(html, selector, text, opts \\ []) do
    elements_matched_selector =
      html
      |> Html.parse()
      |> Html.all(selector)

    elements_matched_selector
    |> filter_by_position(opts)
    |> filter_by_text(text, opts)
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
      Enum.map(elements, fn
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

  def find_by_label!(html, label) do
    case find_by_label(html, label) do
      {:found, element} ->
        element

      {:not_found, :no_label, []} ->
        msg = """
        Could not find element with label #{inspect(label)}
        """

        raise ArgumentError, msg

      {:not_found, :no_label, potential_matches} ->
        msg = """
        Could not find element with label #{inspect(label)}.

        Found the following labels:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      {:not_found, :found_many_labels, potential_matches} ->
        msg = """
        Found many elements with label #{inspect(label)}:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      {:not_found, :missing_for, found_label} ->
        msg = """
        Found label but doesn't have `for` attribute.

        (Label's `for` attribute must point to element's `id`)

        Label found:

        #{Html.raw(found_label)}
        """

        raise ArgumentError, msg

      {:not_found, :missing_id, found_label} ->
        msg = """
        Found label but could not find corresponding element with matching `id`.

        (Label's `for` attribute must point to element's `id`)

        Label found:

        #{Html.raw(found_label)}
        """

        raise ArgumentError, msg
    end
  end

  def find_by_label(html, label) do
    with {:explicit_association, label_element} <- find_label_element(html, label),
         {:ok, label_for} <- label_for(label_element),
         {:found, element} <- find_element_with_id(html, label_for, label_element) do
      {:found, element}
    else
      {:implicit_association, _label_element, element} ->
        {:found, element}

      not_found ->
        not_found
    end
  end

  def find_ancestor!(html, ancestor, {descendant_selector, descendant_text} = desc) do
    case find_ancestor(html, ancestor, desc) do
      {:found, element} ->
        element

      {:found_many, potential_matches} ->
        msg = """
        Found too many #{inspect(ancestor)} elements with nested element with
        selector #{inspect(descendant_selector)} and text #{inspect(descendant_text)}

        Potential matches:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      :not_found ->
        msg = """
        Could not find any #{inspect(ancestor)} elements.
        """

        raise ArgumentError, msg

      {:not_found, potential_matches} ->
        msg = """
        Could not find #{inspect(ancestor)} for an element with selector #{inspect(descendant_selector)} and text #{inspect(descendant_text)}.

        Found other potential #{inspect(ancestor)}:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg
    end
  end

  def find_ancestor!(html, ancestor, descendant_selector) do
    case find_ancestor(html, ancestor, descendant_selector) do
      {:found, element} ->
        element

      :not_found ->
        msg = """
        Could not find any #{inspect(ancestor)} elements.
        """

        raise ArgumentError, msg

      {:not_found, potential_matches} ->
        msg = """
        Could not find #{inspect(ancestor)} for an element with selector #{inspect(descendant_selector)}.

        Found other potential #{inspect(ancestor)}:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg
    end
  end

  def find_ancestor(html, ancestor_selector, {descendant_selector, descendant_text}) do
    case find(html, ancestor_selector) do
      :not_found ->
        :not_found

      {:found, element} ->
        filter_ancestor_with_descendant([element], descendant_selector, descendant_text)

      {:found_many, elements} ->
        filter_ancestor_with_descendant(elements, descendant_selector, descendant_text)
    end
  end

  def find_ancestor(html, ancestor_selector, descendant_selector) do
    case find(html, ancestor_selector) do
      :not_found ->
        :not_found

      {:found, element} ->
        filter_ancestor_with_descendant([element], descendant_selector)

      {:found_many, elements} ->
        filter_ancestor_with_descendant(elements, descendant_selector)
    end
  end

  defp filter_ancestor_with_descendant(ancestors, descendant_selector, descendant_text) do
    ancestors
    |> Enum.filter(fn ancestor ->
      case find(Html.raw(ancestor), descendant_selector, descendant_text) do
        {:not_found, _} -> false
        {:found, _element} -> true
        {:found_many, _elements} -> true
      end
    end)
    |> case do
      [] -> {:not_found, ancestors}
      [ancestor] -> {:found, ancestor}
      [_ | _] = ancestors -> {:found_many, ancestors}
    end
  end

  defp filter_ancestor_with_descendant(ancestors, descendant_selector) do
    ancestors
    |> Enum.filter(fn ancestor ->
      case find(Html.raw(ancestor), descendant_selector) do
        :not_found -> false
        {:found, _element} -> true
        {:found_many, _elements} -> true
      end
    end)
    |> case do
      [] -> {:not_found, ancestors}
      [ancestor] -> {:found, ancestor}
    end
  end

  defp find_label_element(html, label) do
    find(html, "label", label, exact: true)
    |> case do
      {:not_found, potential_matches} ->
        {:not_found, :no_label, potential_matches}

      {:found, element} ->
        determine_implicit_or_explicit_label(element)

      {:found_many, elements} ->
        {:not_found, :found_many_labels, elements}
    end
  end

  defp determine_implicit_or_explicit_label(label) do
    case find_one_of(Html.raw(label), ["input", "select", "textarea"]) do
      {:not_found, _} ->
        {:explicit_association, label}

      {:found, element} ->
        {:implicit_association, label, element}
    end
  end

  defp label_for(label) do
    case Html.attribute(label, "for") do
      nil ->
        {:not_found, :missing_for, label}

      for_attr ->
        {:ok, for_attr}
    end
  end

  defp find_element_with_id(html, id, label) do
    case find(html, "##{id}") do
      :not_found -> {:not_found, :missing_id, label}
      {:found, _el} = found -> found
    end
  end

  defp filter_by_text(elements, text, opts) do
    exact_match = Keyword.get(opts, :exact, false)

    filter_fun =
      if exact_match do
        fn element -> Html.text(element) == text end
      else
        fn element -> Html.text(element) =~ text end
      end

    Enum.filter(elements, filter_fun)
  end

  defp filter_by_position(elements, opts) do
    at = Keyword.get(opts, :at, :any)

    case at do
      :any ->
        elements

      at when is_number(at) ->
        elements |> Enum.at(at - 1) |> List.wrap()
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
