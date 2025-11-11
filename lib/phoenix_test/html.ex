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

  @dont_include_children_tags ~w[select textarea]
  defp text_from_text_nodes(tree, acc \\ "")

  defp text_from_text_nodes([], acc), do: acc

  defp text_from_text_nodes([node | rest], acc) do
    acc =
      case node do
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
