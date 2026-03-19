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

  # Tags where aria-label is NOT supported (per MDN/ARIA spec)
  @aria_label_unsupported_tags ~w[
    caption code del em ins mark p strong sub sup time
  ]

  def element_text(%LazyHTML{} = element) do
    aria_label = attribute(element, "aria-label")
    alt_text = attribute(element, "alt")
    tag_name = tag_name(element)

    cond do
      tag_name not in @aria_label_unsupported_tags and is_binary(aria_label) and String.trim(aria_label) != "" ->
        aria_label

      image_type?(element) and is_binary(alt_text) and String.trim(alt_text) != "" ->
        alt_text

      true ->
        element
        |> LazyHTML.to_tree(skip_whitespace_nodes: true)
        |> text_from_text_nodes()
        |> String.trim()
        |> normalize_whitespace()
    end
  end

  defp image_type?(element) do
    tag_name(element) == "img" or attribute(element, "type") == "image"
  end

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

  def tag_name(%LazyHTML{} = element) do
    element
    |> LazyHTML.tag()
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
