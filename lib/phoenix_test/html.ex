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
    element
    |> LazyHTML.to_tree(skip_whitespace_nodes: true)
    |> text_from_text_nodes()
    |> String.trim()
    |> normalize_whitespace()
  end

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
          case get_image_alt(attrs) do
            :no_alt -> acc
            alt_text -> acc <> " " <> alt_text
          end

        {"input", attrs, children} ->
          case get_attr_value(attrs, "type") do
            "image" ->
              case get_image_alt(attrs) do
                :no_alt -> acc
                alt_text -> acc <> " " <> alt_text
              end

            _ ->
              acc <> " " <> text_from_text_nodes(children)
          end

        text when is_binary(text) ->
          acc <> " " <> text

        {tag, attrs, children} ->
          aria_label = get_attr_value(attrs, "aria-label")

          cond do
            tag not in @aria_label_unsupported_tags and is_binary(aria_label) and
                String.trim(aria_label) != "" ->
              acc <> " " <> aria_label

            top_level_tag?(acc) or tag not in @dont_include_children_tags ->
              acc <> text_from_text_nodes(children)

            true ->
              acc
          end

        _ ->
          acc
      end

    text_from_text_nodes(rest, acc)
  end

  defp top_level_tag?("" = _previous_text), do: true
  defp top_level_tag?(_previous_text), do: false

  defp get_image_alt(attrs) do
    case get_attr_value(attrs, "alt") do
      nil -> :no_alt
      "" -> :no_alt
      alt_text -> alt_text
    end
  end

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
