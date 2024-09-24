defmodule PhoenixTest.Query do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Locators

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

  def find!(html, selector, text, opts \\ []) do
    case find(html, selector, text, opts) do
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

  def find(html, selector) do
    find(html, selector, [])
  end

  def find(html, selector, opts) when is_list(opts) do
    html
    |> Html.parse()
    |> Html.all(selector)
    |> filter_by_position(opts)
    |> case do
      [] ->
        :not_found

      [element] ->
        {:found, element}

      [_ | _] = elements ->
        {:found_many, elements}
    end
  end

  def find(html, selector, text, opts \\ []) when is_binary(text) and is_list(opts) do
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

  def find_by_role!(html, locator) do
    selectors = Locators.role_selectors(locator)

    find_one_of!(html, selectors)
  end

  def find_one_of!(html, elements) do
    html
    |> find_one_of(elements)
    |> case do
      {:not_found, []} ->
        raise ArgumentError, """
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors: #{format_selectors_for_error_msg(elements)}
        """

      {:not_found, potential_matches} ->
        raise ArgumentError, """
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors: #{format_selectors_for_error_msg(elements)}

        I found some elements that match the selector but not the content:

        #{format_potential_matches(potential_matches)}
        """

      {:found, found_element} ->
        found_element

      {:found_many, found_elements} ->
        raise ArgumentError, """
        Found too many matches for given selectors: #{format_selectors_for_error_msg(elements)}

        Here's what I found:

        #{format_potential_matches(found_elements)}
        """
    end
  end

  def find_one_of(html, elements) do
    results =
      Enum.map(elements, fn
        {selector, text} -> find(html, selector, text)
        selector -> find(html, selector)
      end)

    results
    |> Enum.filter(fn
      :not_found -> false
      {:not_found, _} -> false
      {:found, _} -> true
      {:found_many, _} -> true
    end)
    |> case do
      [] ->
        {:not_found, potential_matches(results)}

      [found] ->
        found

      [_, _] = found_many ->
        {:found_many, Enum.map(found_many, &elem(&1, 1))}
    end
  end

  def find_by_label!(html, input_selectors, label) do
    input_selectors = List.wrap(input_selectors)

    case find_by_label(html, input_selectors, label) do
      {:found, element} ->
        element

      {:not_found, :no_label, []} ->
        msg = """
        Could not find element with label #{inspect(label)}
        """

        raise ArgumentError, msg

      {:not_found, :no_label, potential_matches} ->
        msg = """
        Could not find element with label #{inspect(label)} and provided selectors.

        Labels found
        ============

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}

        Searched for labeled elements with these selectors: #{format_selectors_for_error_msg(input_selectors)}
        """

        raise ArgumentError, msg

      {:not_found, :missing_for, found_label} ->
        msg = """
        Found label, but it doesn't have `for` attribute.

        (Label's `for` attribute must point to element's `id`)

        Label found
        ===========

        #{Html.raw(found_label)}
        """

        raise ArgumentError, msg

      {:not_found, :missing_input, found_label} ->
        msg = """
        Found label but can't find labeled element whose `id` matches label's `for` attribute.

        (Label's `for` attribute must point to element's `id`)

        Label found
        ===========

        #{Html.raw(found_label)}

        Searched for elements with these selectors: #{format_selectors_for_error_msg(input_selectors)}
        """

        raise ArgumentError, msg

      {:not_found, :found_many_labels, potential_matches} ->
        msg = """
        Found many labels with text #{inspect(label)}:

        #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      {:not_found, :found_many_labels_with_inputs, label_elements, input_elements} ->
        msg = """
        Found many elements with label #{inspect(label)} and matching the provided selectors.

        Labels found
        ============

        #{Enum.map_join(label_elements, "\n", &Html.raw/1)}

        Elements found
        ==============

        #{Enum.map_join(input_elements, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

      {:not_found, :mismatched_id, label_element, input_element} ->
        msg = """
        Found label and labeled element matching provided selectors. But the
        label's `for` attribute did not match the labeled element's `id`.

        Label found
        ============

        #{Html.raw(label_element)}

        Element found
        =============

        #{Html.raw(input_element)}

        Searched for elements with these selectors: #{format_selectors_for_error_msg(input_selectors)}
        """

        raise ArgumentError, msg
    end
  end

  def find_by_label(html, input_selectors, label) do
    input_selectors = List.wrap(input_selectors)

    case find_labels(html, input_selectors, label) do
      {:implicit_association, _label_element, element} ->
        {:found, element}

      {:explicit_association, label_element} ->
        find_label_input(html, input_selectors, label_element)

      {:found_many, label_elements} ->
        label_elements
        |> Enum.map(&find_label_input(html, input_selectors, &1))
        |> Enum.filter(fn
          {:found, _} -> true
          _ -> false
        end)
        |> case do
          [] -> {:not_found, :found_many_labels, label_elements}
          [{:found, element}] -> {:found, element}
          [_ | _] = found -> {:not_found, :found_many_labels_with_inputs, label_elements, Enum.map(found, &elem(&1, 1))}
        end

      {:not_found, potential_matches} ->
        {:not_found, :no_label, potential_matches}
    end
  end

  defp find_labels(html, input_selectors, label) do
    html
    |> find("label", label, exact: true)
    |> case do
      {:not_found, potential_matches} ->
        {:not_found, potential_matches}

      {:found, element} ->
        determine_implicit_or_explicit_label(element, input_selectors)

      {:found_many, elements} ->
        {:found_many, elements}
    end
  end

  defp find_label_input(html, input_selectors, label_element) do
    with {:ok, label_for} <- label_for(label_element) do
      find_associated_input(html, input_selectors, label_for, label_element)
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

      {:found_many, ancestors} ->
        msg = """
        Found too many #{inspect(ancestor)} matches for element with selector #{inspect(descendant_selector)}

        Please make the selector more specific (e.g. using an id)

        The following #{inspect(ancestor)} elements were found:

        #{Enum.map_join(ancestors, "\n", &Html.raw/1)}
        """

        raise ArgumentError, msg

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
      [_ | _] = ancestors -> {:found_many, ancestors}
    end
  end

  defp determine_implicit_or_explicit_label(label, input_selectors) do
    case find_one_of(Html.raw(label), input_selectors) do
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

  defp find_associated_input(html, input_selectors, label_for, label) do
    selectors = combine_selectors(input_selectors, label_for)

    case find_one_of(html, selectors) do
      {:not_found, _} ->
        {:not_found, :missing_input, label}

      {:found, element} = found ->
        case Html.attribute(element, "id") do
          ^label_for -> found
          _ -> {:not_found, :mismatched_id, label, element}
        end
    end
  end

  defp combine_selectors(input_selectors, label_for) when is_list(input_selectors) do
    Enum.map(input_selectors, &combine_selector(&1, label_for))
  end

  defp combine_selector(input_selector, label_for) do
    if Element.selector_has_id?(input_selector) do
      input_selector
    else
      input_selector <> "[id='#{label_for}']"
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

  defp format_selectors_for_error_msg([selector_and_text]) do
    case selector_and_text do
      {selector, text} ->
        "#{inspect(selector)} with content #{inspect(text)}"

      selector ->
        inspect(selector)
    end
  end

  defp format_selectors_for_error_msg(selectors_and_text) do
    "\n\n" <>
      Enum.map_join(selectors_and_text, "\n", fn
        {selector, text} ->
          "- #{inspect(selector)} with content #{inspect(text)}"

        selector ->
          "- #{inspect(selector)}"
      end)
  end
end
