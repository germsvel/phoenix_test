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
end
