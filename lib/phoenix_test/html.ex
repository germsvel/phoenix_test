defmodule PhoenixTest.Html do
  @moduledoc false

  def parse_document(%LazyHTML{} = html), do: html

  def parse_document(html) when is_binary(html) do
    LazyHTML.from_document(html)
  end

  def parse_fragment(%LazyHTML{} = html), do: html

  def parse_fragment(html) when is_binary(html) do
    LazyHTML.from_fragment(html)
  end

  def element_text(%LazyHTML{} = element) do
    # Check for aria-label if the element supports it
    case aria_label_text(element) do
      nil ->
        # No aria-label: check if element itself has alt attribute (for input[type="image"])
        case alt_text_for_element(element) do
          nil ->
            # No alt on element: extract content text (including alt from child images)
            element
            |> LazyHTML.to_tree(skip_whitespace_nodes: true)
            |> text_from_text_nodes()
            |> String.trim()
            |> normalize_whitespace()

          alt_text ->
            # Element has alt attribute (e.g., input[type="image"])
            alt_text
        end

      aria_text ->
        # Use aria-label (replaces content like screen readers do)
        aria_text
    end
  end

  # Tags where aria-label is NOT supported (per MDN/ARIA spec)
  @aria_label_unsupported_tags ~w[
    caption code del em ins mark p strong sub sup time
  ]

  @dont_include_children_tags ~w[select textarea]
  defp text_from_text_nodes(tree, acc \\ "")

  defp text_from_text_nodes([], acc), do: acc

  defp text_from_text_nodes([node | rest], acc) do
    acc =
      case node do
        {"img", attrs, _} ->
          # Extract alt attribute from img tags
          case get_attr_value(attrs, "alt") do
            nil -> acc
            "" -> acc
            alt_text -> acc <> " " <> alt_text
          end

        text when is_binary(text) ->
          acc <> text

        {tag, _, children} when tag not in @dont_include_children_tags ->
          acc <> " " <> text_from_text_nodes(children)

        {_tag, _, children} ->
          if top_level_tag?(acc) do
            acc <> " " <> text_from_text_nodes(children)
          else
            acc
          end

        _ ->
          acc
      end

    text_from_text_nodes(rest, acc)
  end

  defp top_level_tag?("" = _previous_text), do: true
  defp top_level_tag?(_previous_text), do: false

  # Check if element has aria-label and if the tag supports it
  defp aria_label_text(%LazyHTML{} = element) do
    with label when is_binary(label) and label != "" <- attribute(element, "aria-label"),
         trimmed = String.trim(label),
         true <- trimmed != "",
         tree when is_tuple(tree) <- element(element),
         {tag, _, _} <- tree,
         false <- tag in @aria_label_unsupported_tags do
      trimmed
    else
      _ -> nil
    end
  end

  # Check if element itself has an alt attribute (for elements like input[type="image"])
  defp alt_text_for_element(%LazyHTML{} = element) do
    case attribute(element, "alt") do
      alt when is_binary(alt) and alt != "" -> String.trim(alt)
      _ -> nil
    end
  end

  # Helper to extract attribute value from attrs list in tree nodes
  defp get_attr_value(attrs, attr_name) when is_list(attrs) do
    Enum.find_value(attrs, fn
      {^attr_name, value} -> value
      _ -> nil
    end)
  end

  def attribute(%LazyHTML{} = element, attr) when is_binary(attr) do
    element
    |> LazyHTML.attribute(attr)
    |> List.first()
  end

  def attributes(%LazyHTML{} = element) do
    element
    |> LazyHTML.attributes()
    |> List.first()
  end

  def all(%LazyHTML{} = html, selector) when is_binary(selector) do
    LazyHTML.query(html, selector)
  end

  def raw(%LazyHTML{} = html), do: LazyHTML.to_html(html)

  def postwalk(%LazyHTML{} = html, postwalk_fun) when is_function(postwalk_fun, 1) do
    html
    |> LazyHTML.to_tree()
    |> LazyHTML.Tree.postwalk(postwalk_fun)
    |> LazyHTML.from_tree()
  end

  def element(%LazyHTML{} = html) do
    case Enum.at(html, 0) do
      nil -> nil
      %LazyHTML{} = element -> element |> LazyHTML.to_tree() |> hd()
    end
  end

  defp normalize_whitespace(string) do
    String.replace(string, ~r/[\s]+/, " ")
  end
end
