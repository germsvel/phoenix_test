defmodule PhoenixTest.Html do
  @moduledoc false

  def parse(html) do
    html
    |> Floki.parse_document!()
  end

  def text(element), do: Floki.text(element) |> String.trim()

  def attribute(element, attr) do
    element
    |> Floki.attribute(attr)
    |> List.first()
  end

  def all(html, selector) do
    Floki.find(html, selector)
  end

  def raw(html_string), do: Floki.raw_html(html_string, pretty: true)
end
