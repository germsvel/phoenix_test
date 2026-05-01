defmodule PhoenixTest.Query.LabelError do
  @moduledoc false

  alias PhoenixTest.Html

  def message({:not_found, :no_label, potential_matches}, label, opts) do
    if Enum.empty?(potential_matches) do
      """
      Could not find element with label #{inspect(label)}
      """
    else
      """
      Could not find element with label #{inspect(label)} and provided selectors #{inspect(opts[:input_selectors])}.

      Labels found
      ============

      #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}

      Searched for labeled elements with these selectors: #{opts[:formatted_selectors]}
      """
    end
  end

  def message({:not_found, :missing_for, found_label}, _label, _opts) do
    """
    Found label, but it doesn't have `for` attribute.

    (Label's `for` attribute must point to element's `id`)

    Label found
    ===========

    #{Html.raw(found_label)}
    """
  end

  def message({:not_found, :missing_input, found_label}, _label, opts) do
    """
    Found label but can't find labeled element whose `id` matches label's `for` attribute.

    (Label's `for` attribute must point to element's `id`)

    Label found
    ===========

    #{Html.raw(found_label)}

    Searched for elements with these selectors: #{opts[:formatted_selectors]}
    """
  end

  def message({:not_found, :found_many_labels, potential_matches}, label, _opts) do
    """
    Found many labels with text #{inspect(label)}:

    #{Enum.map_join(potential_matches, "\n", &Html.raw/1)}
    """
  end

  def message({:not_found, :found_many_labels_with_inputs, label_elements, input_elements}, label, _opts) do
    """
    Found many elements with label #{inspect(label)} and matching the provided selectors.

    Labels found
    ============

    #{Enum.map_join(label_elements, "\n", &Html.raw/1)}

    Elements found
    ==============

    #{Enum.map_join(input_elements, "\n", &Html.raw/1)}
    """
  end

  def message({:not_found, :mismatched_id, label_element, input_element}, _label, opts) do
    """
    Found label and labeled element matching provided selectors. But the
    label's `for` attribute did not match the labeled element's `id`.

    Label found
    ============

    #{Html.raw(label_element)}

    Element found
    =============

    #{Html.raw(input_element)}

    Searched for elements with these selectors: #{opts[:formatted_selectors]}
    """
  end
end
