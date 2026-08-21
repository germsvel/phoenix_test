defmodule PhoenixTest.QueryFailure do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query.Failure

  # This module is intentionally outside PhoenixTest.Query: lookup failures are
  # data, while callers decide whether and how to present them.

  def unwrap!({:ok, value}), do: value
  def unwrap!({:error, %Failure{} = failure}), do: raise_argument_error!(failure)

  def raise_argument_error!(%Failure{} = failure), do: raise(ArgumentError, argument_error_message(failure))

  def argument_error_message(%Failure{
        operation: operation,
        kind: :not_found,
        request: %{selector: selector, text: text},
        candidates: candidates
      })
      when operation in [:find, :find_first] do
    if Enum.any?(candidates) do
      """
      Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

      The following elements matching the selector were found:

      #{format_elements(candidates)}
      """
    else
      """
      Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.
      """
    end
  end

  def argument_error_message(%Failure{operation: :find, kind: :not_found, request: %{selector: selector}}),
    do: "Could not find element with selector #{inspect(selector)}"

  def argument_error_message(%Failure{
        operation: operation,
        kind: :multiple_matches,
        request: %{selector: selector, text: text}
      })
      when operation in [:find, :find_first],
      do: "Found more than one element with selector #{inspect(selector)} and text #{inspect(text)}."

  def argument_error_message(%Failure{operation: :find, kind: :multiple_matches, request: %{selector: selector}}),
    do: "Found more than one element with selector #{inspect(selector)}"

  def argument_error_message(%Failure{operation: operation, request: %{role_selectors: selectors}} = failure)
      when operation == :find_by_role,
      do: one_of_message(%{failure | operation: :find_one_of, request: %{selectors: selectors}})

  def argument_error_message(%Failure{operation: :find_one_of} = failure), do: one_of_message(failure)
  def argument_error_message(%Failure{operation: :find_by_label} = failure), do: label_message(failure)
  def argument_error_message(%Failure{operation: :find_by_selected} = failure), do: selected_message(failure)

  def argument_error_message(%Failure{operation: :find_by_label_and_selected, kind: kind} = failure)
      when kind in [:not_found, :multiple_matches], do: label_and_selected_message(failure)

  def argument_error_message(%Failure{operation: :find_by_label_and_selected} = failure), do: label_message(failure)

  def argument_error_message(%Failure{
        operation: :find_ancestor,
        kind: :not_found,
        request: %{ancestor_selector: ancestor},
        candidates: []
      }),
      do: """
      Could not find any #{inspect(ancestor)} elements.
      """

  def argument_error_message(%Failure{
        operation: :find_ancestor,
        kind: :not_found,
        request: %{ancestor_selector: ancestor, descendant: descendant},
        candidates: candidates
      }),
      do: """
      Could not find #{inspect(ancestor)} for an element with #{descendant_description(descendant)}.

      Found other potential #{inspect(ancestor)}:

      #{format_elements(candidates)}
      """

  def argument_error_message(%Failure{
        operation: :find_ancestor,
        kind: :multiple_matches,
        request: %{ancestor_selector: ancestor, descendant: {selector, text}},
        candidates: candidates
      }),
      do: """
      Found too many #{inspect(ancestor)} elements with nested element with
      selector #{inspect(selector)} and text #{inspect(text)}

      Potential matches:

      #{format_elements(candidates)}
      """

  def argument_error_message(%Failure{
        operation: :find_ancestor,
        kind: :multiple_matches,
        request: %{ancestor_selector: ancestor, descendant: descendant},
        candidates: candidates
      }),
      do: """
      Found too many #{inspect(ancestor)} matches for element with selector #{inspect(descendant)}

      Please make the selector more specific (e.g. using an id)

      The following #{inspect(ancestor)} elements were found:

      #{format_elements(candidates)}
      """

  # Keep exception conversion reliable if a future Query failure is introduced
  # before this formatter gains an operation-specific clause.
  def argument_error_message(%Failure{} = failure), do: fallback_message(failure)

  defp one_of_message(%Failure{kind: :not_found, request: %{selectors: selectors}, candidates: candidates}) do
    message = """
    Could not find an element with given selectors.

    I was looking for an element with one of these selectors: #{format_selectors(selectors)}
    """

    if Enum.any?(candidates),
      do:
        message <>
          "\nI found some elements that match the selector but not the content:\n\n#{format_elements(candidates)}\n",
      else: message
  end

  defp one_of_message(%Failure{kind: :multiple_matches, request: %{selectors: selectors}, candidates: candidates}),
    do: """
    Found too many matches for given selectors: #{format_selectors(selectors)}

    Here's what I found:

    #{format_elements(candidates)}
    """

  defp one_of_message(%Failure{} = failure), do: fallback_message(failure)

  defp label_message(%Failure{kind: :no_label, request: %{label: label}, labels: []}),
    do: """
    Could not find element with label #{inspect(label)}
    """

  defp label_message(%Failure{kind: :no_label, request: %{label: label, input_selectors: selectors}, labels: labels}),
    do: """
    Could not find element with label #{inspect(label)} and provided selectors #{inspect(selectors)}.

    Labels found
    ============

    #{format_elements(labels)}

    Searched for labeled elements with these selectors: #{format_selectors(selectors)}
    """

  defp label_message(%Failure{kind: :missing_label_for, labels: [label | _]}),
    do: """
    Found label, but it doesn't have `for` attribute.

    (Label's `for` attribute must point to element's `id`)

    Label found
    ===========

    #{Html.raw(label)}
    """

  defp label_message(%Failure{kind: kind, labels: [label | _], request: %{input_selectors: selectors}})
       when kind in [:missing_labeled_input, :mismatched_label_for],
       do: """
       Found label but can't find labeled element whose `id` matches label's `for` attribute.

       (Label's `for` attribute must point to element's `id`)

       Label found
       ===========

       #{Html.raw(label)}

       Searched for elements with these selectors: #{format_selectors(selectors)}
       """

  defp label_message(%Failure{kind: :multiple_labels, request: %{label: label}, labels: labels}),
    do: """
    Found many labels with text #{inspect(label)}:

    #{format_elements(labels)}
    """

  defp label_message(%Failure{kind: :multiple_matches, request: %{label: label}, labels: labels, candidates: candidates}),
    do: """
    Found many elements with label #{inspect(label)} and matching the provided selectors.

    Labels found
    ============

    #{format_elements(labels)}

    Elements found
    ==============

    #{format_elements(candidates)}
    """

  defp label_message(%Failure{kind: :conflicting_label_associations, labels: [label | _]}),
    do: """
    Found a label which references two different inputs.

    Please remove either the 'for' attribute or the nested input

    to ensure the correct input can be targeted:

    #{Html.raw(label)}
    """

  defp label_message(%Failure{} = failure), do: fallback_message(failure)

  defp selected_message(%Failure{
         kind: :not_found,
         request: %{selector: selector, selected: selected},
         candidates: candidates
       }) do
    message = "Could not find element with selector #{inspect(selector)} and selected option #{inspect(selected)}."

    if Enum.any?(candidates),
      do: message <> "\n\nThe following elements matching the selector were found:\n\n#{format_elements(candidates)}",
      else: message
  end

  defp selected_message(%Failure{kind: :multiple_matches, request: %{selector: selector, selected: selected}}),
    do: "Found more than one element with selector #{inspect(selector)} and selected option #{inspect(selected)}."

  defp selected_message(%Failure{} = failure), do: fallback_message(failure)

  defp label_and_selected_message(%Failure{
         kind: :not_found,
         request: %{label: label, selected: selected},
         candidates: candidates
       }) do
    message = "Could not find element with label #{inspect(label)} and selected option #{inspect(selected)}."

    if Enum.any?(candidates),
      do: message <> "\n\nThe following labeled elements were found:\n\n#{format_elements(candidates)}",
      else: message
  end

  defp label_and_selected_message(%Failure{
         kind: :multiple_matches,
         request: %{label: label, selected: selected},
         candidates: candidates
       }),
       do:
         "Found more than one element with label #{inspect(label)} and selected option #{inspect(selected)}.\n\nPotential matches:\n\n#{format_elements(candidates)}"

  defp label_and_selected_message(%Failure{} = failure), do: fallback_message(failure)

  defp fallback_message(%Failure{operation: operation, kind: kind, request: request, candidates: candidates}) do
    message =
      "Could not complete query operation #{inspect(operation)} (#{inspect(kind)}).\n\nRequest: #{inspect(request)}"

    if Enum.any?(candidates), do: message <> "\n\nCandidates:\n\n#{format_elements(candidates)}", else: message
  end

  defp descendant_description({selector, text}), do: "selector #{inspect(selector)} and text #{inspect(text)}"
  defp descendant_description(selector), do: "selector #{inspect(selector)}"

  defp format_elements(elements), do: Enum.map_join(List.wrap(elements), "\n", &Html.raw/1)

  defp format_selectors([selector]), do: format_selector(selector)
  defp format_selectors(selectors), do: "\n\n" <> Enum.map_join(selectors, "\n", &"- #{format_selector(&1)}")
  defp format_selector({selector, text}), do: "#{inspect(selector)} with content #{inspect(text)}"
  defp format_selector(selector), do: inspect(selector)
end
