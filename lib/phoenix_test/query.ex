defmodule PhoenixTest.Query do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Locators
  alias PhoenixTest.Query.Failure

  # Query is internal. All lookup functions return {:ok, value} or {:error, failure}.
  # LazyHTML parsing and selector errors intentionally propagate.

  def find(html, selector), do: find(html, selector, [])

  def find(html, selector, opts) when is_list(opts) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector) |> filter_by_position(opts)
    one_result(:find, %{selector: selector, opts: opts}, candidates)
  end

  def find(html, selector, text, opts \\ []) when is_binary(text) and is_list(opts) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector)
    matches = candidates |> filter_by_position(opts) |> filter_by_element_text(text, opts)

    one_result(:find, %{selector: selector, text: text, opts: opts}, matches, candidates: candidates)
  end

  # Data-only lookup for callers that intentionally need the first match (for
  # example, a form's default submit button), rather than Query.find/2's
  # exactly-one matching semantics.
  def find_first(html, selector) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector)

    case Enum.to_list(candidates) do
      [element | _] -> {:ok, element}
      [] -> error(:not_found, :find, %{selector: selector})
    end
  end

  def find_first(html, selector, text, opts \\ []) when is_binary(text) and is_list(opts) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector)

    case find_first_by_element_text(candidates, text, opts) do
      nil -> error(:not_found, :find_first, %{selector: selector, text: text, opts: opts}, candidates: candidates)
      element -> {:ok, element}
    end
  end

  def find_by_selected(html, selector, selected, opts \\ []) when is_binary(selected) and is_list(opts) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector)
    matches = candidates |> filter_by_position(opts) |> Enum.filter(&(selected in selected_option_texts(&1)))
    one_result(:find_by_selected, %{selector: selector, selected: selected, opts: opts}, matches, candidates: candidates)
  end

  def find_by_label_and_selected(html, input_selectors, label, selected, opts \\ [])
      when is_binary(selected) and is_list(opts) do
    request = %{input_selectors: List.wrap(input_selectors), label: label, selected: selected, opts: opts}

    case find_by_label(html, input_selectors, label, opts) do
      {:ok, element} ->
        selected_result([element], selected, request)

      {:error, %Failure{kind: :multiple_matches, inputs: inputs}} ->
        selected_result(inputs, selected, request)

      {:error, failure} ->
        {:error, %{failure | operation: :find_by_label_and_selected, request: request}}
    end
  end

  def find_by_role(html, %Locators.Button{text: text, selectors: selectors} = locator) do
    request = %{locator: locator, role_selectors: Locators.role_selectors(locator), label: text}

    case find_one_of(html, request.role_selectors) do
      {:ok, element} ->
        {:ok, element}

      {:error, %Failure{kind: :not_found} = failure} ->
        case find_by_label(html, selectors, text, exact: false) do
          {:ok, element} ->
            {:ok, element}

          {:error, label_failure} ->
            {:error,
             %{
               failure
               | operation: :find_by_role,
                 request: request,
                 details: Map.put(failure.details, :label_failure, label_failure)
             }}
        end

      {:error, failure} ->
        {:error, %{failure | operation: :find_by_role, request: request}}
    end
  end

  def find_one_of(html, elements) do
    results =
      Enum.map(elements, fn
        {selector, text} -> find(html, selector, text)
        selector -> find(html, selector)
      end)

    found =
      Enum.flat_map(results, fn
        {:ok, element} -> [element]
        {:error, %Failure{kind: :multiple_matches, candidates: elements}} -> List.wrap(elements)
        {:error, _} -> []
      end)

    request = %{selectors: elements}

    case found do
      [] -> error(:not_found, :find_one_of, request, candidates: potential_matches(results), details: %{results: results})
      [element] -> {:ok, element}
      elements -> error(:multiple_matches, :find_one_of, request, candidates: elements, details: %{results: results})
    end
  end

  def find_by_label(html, input_selectors, label, opts \\ [exact: true]) do
    input_selectors = List.wrap(input_selectors)
    request = %{input_selectors: input_selectors, label: label, opts: opts}

    case find_by_label_element(html, input_selectors, label, opts, request) do
      {:ok, _} = found ->
        found

      {:error, failure} ->
        case find_by_aria(html, input_selectors, label, opts, request) do
          {:error, %Failure{kind: :not_found}} -> {:error, failure}
          result -> result
        end
    end
  end

  def find_ancestor(html, ancestor_selector, descendant) do
    descendant = descendant_selector(descendant)
    request = %{ancestor_selector: ancestor_selector, descendant: descendant}

    with {:ok, ancestors} <- all(html, ancestor_selector, request) do
      matches = filter_ancestors(ancestors, descendant)
      one_result(:find_ancestor, request, matches, candidates: ancestors)
    end
  end

  def has_ancestor?(html, ancestor_selector, descendant),
    do: match?({:ok, _}, find_ancestor(html, ancestor_selector, descendant))

  defp find_by_label_element(html, selectors, label, opts, request) do
    case find_labels(html, selectors, label, opts, request) do
      {:ok, [{:implicit, _label, element}]} ->
        {:ok, element}

      {:ok, [{:explicit, label_element}]} ->
        find_explicit_label_input(html, selectors, label_element, request)

      {:ok, labels, associations} ->
        results =
          Enum.map(associations, fn
            {:ok, {:implicit, _, element}} -> {:ok, element}
            {:ok, {:explicit, label_element}} -> find_explicit_label_input(html, selectors, label_element, request)
            {:error, failure} -> {:error, failure}
          end)

        inputs = for {:ok, element} <- results, do: element
        details = %{associations: associations, results: results}

        case inputs do
          [] ->
            error(:multiple_labels, :find_by_label, request, labels: labels, details: details)

          [element] ->
            {:ok, element}

          _ ->
            error(:multiple_matches, :find_by_label, request, labels: labels, inputs: inputs, details: details)
        end

      {:error, failure} ->
        {:error, failure}
    end
  end

  defp find_labels(html, selectors, label, opts, request) do
    case find(html, "label", label, opts) do
      {:ok, element} ->
        case association(html, element, selectors, request) do
          {:ok, value} -> {:ok, [value]}
          {:error, failure} -> {:error, failure}
        end

      {:error, %Failure{kind: :multiple_matches, candidates: labels}} ->
        {:ok, labels, Enum.map(labels, &association(html, &1, selectors, request))}

      {:error, failure} ->
        error(:no_label, :find_by_label, %{input_selectors: selectors, label: label, opts: opts},
          candidates: failure.candidates
        )
    end
  end

  defp association(html, label, selectors, request) do
    explicit = find_explicit_label_input(html, selectors, label, request)
    implicit = find_one_of(label, selectors)

    case {explicit, implicit} do
      {{:ok, explicit}, {:ok, implicit}} ->
        if Html.element(explicit) == Html.element(implicit) do
          {:ok, {:implicit, label, implicit}}
        else
          error(:conflicting_label_associations, :find_by_label, request, labels: [label], inputs: [explicit, implicit])
        end

      {_, {:ok, implicit}} ->
        {:ok, {:implicit, label, implicit}}

      _ ->
        {:ok, {:explicit, label}}
    end
  end

  defp find_explicit_label_input(html, selectors, label, request) do
    case Html.attribute(label, "for") do
      nil ->
        error(:missing_label_for, :find_by_label, request, labels: [label])

      label_for ->
        case find_one_of(html, combine_selectors(selectors, label_for)) do
          {:ok, element} ->
            if Html.attribute(element, "id") == label_for do
              {:ok, element}
            else
              error(:mismatched_label_for, :find_by_label, request,
                labels: [label],
                inputs: [element],
                details: %{for: label_for}
              )
            end

          {:error, failure} ->
            error(:missing_labeled_input, :find_by_label, request,
              labels: [label],
              candidates: failure.candidates,
              details: %{for: label_for}
            )
        end
    end
  end

  defp find_by_aria(html, selectors, label, opts, request) do
    parsed = Html.parse_fragment(html)

    matches =
      Enum.flat_map(selectors, fn selector ->
        parsed |> Html.all(selector) |> Enum.filter(&aria_name_match?(parsed, &1, label, opts))
      end)

    one_result(:find_by_label, request, matches, inputs: matches)
  end

  defp all(html, selector, request) do
    candidates = html |> Html.parse_fragment() |> Html.all(selector)
    if Enum.empty?(candidates), do: error(:not_found, :find_ancestor, request), else: {:ok, candidates}
  end

  defp filter_ancestors(ancestors, {selector, text}), do: Enum.filter(ancestors, &descendant_matches?(&1, selector, text))

  defp filter_ancestors(ancestors, selector), do: Enum.filter(ancestors, &descendant_matches?(&1, selector))

  defp descendant_matches?(html, selector), do: descendant_query_matches?(find(html, selector))

  defp descendant_matches?(html, selector, text), do: descendant_query_matches?(find(html, selector, text))

  defp descendant_query_matches?({:ok, _}), do: true
  defp descendant_query_matches?({:error, %Failure{kind: :multiple_matches}}), do: true
  defp descendant_query_matches?({:error, _}), do: false

  defp one_result(operation, request, matches, opts \\ []) do
    case Enum.to_list(matches) do
      [] -> error(:not_found, operation, request, opts)
      [element] -> {:ok, element}
      elements -> error(:multiple_matches, operation, request, Keyword.put(opts, :candidates, elements))
    end
  end

  defp selected_result(elements, selected, request) do
    matches = Enum.filter(elements, &(selected in selected_option_texts(&1)))
    one_result(:find_by_label_and_selected, Map.put(request, :selected, selected), matches, candidates: elements)
  end

  defp error(kind, operation, request, opts \\ []), do: {:error, Failure.new(kind, operation, request, opts)}

  defp combine_selectors(selectors, label_for),
    do: Enum.map(selectors, &if(Element.selector_has_id?(&1, label_for), do: &1, else: &1 <> "[id='#{label_for}']"))

  defp filter_by_element_text(elements, text, opts),
    do: Enum.filter(elements, &text_match?(Html.element_text(&1), text, opts))

  defp find_first_by_element_text(elements, text, opts),
    do: Enum.find(elements, &text_match?(Html.element_text(&1), text, opts))

  defp text_match?(subject, text, opts),
    do: if(Keyword.get(opts, :exact, false), do: subject == text, else: subject =~ text)

  defp selected_option_texts(element),
    do:
      if(Html.tag(element) == "select",
        do: element |> Html.selected_options() |> Enum.map(&Html.element_text/1),
        else: []
      )

  defp filter_by_position(elements, opts) do
    case Keyword.get(opts, :at, :any) do
      :any -> elements
      at when is_number(at) -> elements |> Enum.at(at - 1) |> List.wrap()
    end
  end

  defp descendant_selector(selector) when is_binary(selector), do: selector
  defp descendant_selector({selector, text}) when is_binary(selector) and is_binary(text), do: {selector, text}
  defp descendant_selector(%{id: id}) when is_binary(id), do: "[id=#{inspect(id)}]"
  defp descendant_selector(%{selector: selector, text: text}), do: {selector, text}
  defp descendant_selector(%{selector: selector}), do: selector

  defp aria_name_match?(parsed, element, label, opts),
    do: aria_label_match?(element, label, opts) or aria_labelledby_match?(parsed, element, label, opts)

  defp aria_label_match?(element, label, opts) do
    case Html.attribute(element, "aria-label") do
      nil -> false
      value -> text_match?(normalize_whitespace(value), label, opts)
    end
  end

  defp aria_labelledby_match?(parsed, element, label, opts) do
    case Html.attribute(element, "aria-labelledby") do
      nil ->
        false

      ids ->
        (text = ids |> String.split() |> Enum.map_join(" ", &labelledby_text(parsed, &1)) |> normalize_whitespace()) != "" and
          text_match?(text, label, opts)
    end
  end

  defp labelledby_text(parsed, id) do
    case parsed |> Html.all("[id='#{id}']") |> Enum.at(0) do
      nil -> ""
      element -> Html.element_text(element)
    end
  end

  defp normalize_whitespace(string), do: string |> String.replace(~r/\s+/, " ") |> String.trim()

  defp potential_matches(results),
    do:
      Enum.flat_map(results, fn
        {:error, %Failure{kind: :not_found, candidates: candidates}} -> List.wrap(candidates)
        _ -> []
      end)
end
