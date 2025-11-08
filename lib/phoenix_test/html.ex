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

  def text(%LazyHTML{} = element) do
    LazyHTML.text(element)
  end

  def element_text(%LazyHTML{} = element) do
    element
    |> LazyHTML.to_tree(skip_whitespace_nodes: true)
    |> text_from_text_nodes()
    |> String.trim()
    |> normalize_whitespace()
  end

  # combination of tags listed in "Text Content" and "Inline Text Semantics" in https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements
  @text_tags ~w[a abbr b bdo blockquote br cite code dfn dd div dl dt em i figcaption figure hr kbd li mark menu ol p pre q rp rt s samp small span strong sub sup time u ul var wbr]
  defp text_from_text_nodes(tree, acc \\ "")

  defp text_from_text_nodes([], acc), do: acc

  defp text_from_text_nodes([node | rest], acc) do
    acc =
      case node do
        text when is_binary(text) ->
          acc <> text

        {tag, _, children} when tag in @text_tags ->
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
