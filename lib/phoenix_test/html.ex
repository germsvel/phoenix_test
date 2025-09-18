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

  @doc """
  Returns the rendered text content of an element and its descendants.
  Similar to Javascript [innerText](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/innerText) property,
  but with the following differences:
  - exclude select `option` labels
  """
  def inner_text(%LazyHTML{} = element) do
    element
    |> LazyHTML.to_tree(skip_whitespace_nodes: false)
    |> text_without_select_options()
    |> String.trim()
    |> normalize_whitespace()
  end

  defp text_without_select_options(tree, acc \\ "")

  defp text_without_select_options([], acc), do: acc

  defp text_without_select_options([node | rest], acc) do
    acc =
      case node do
        {"select", _, _} -> acc
        {:comment, _} -> acc
        {_, _, children} -> acc <> text_without_select_options(children)
        text when is_binary(text) -> acc <> text
      end

    text_without_select_options(rest, acc)
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
