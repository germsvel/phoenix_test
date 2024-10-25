defmodule PhoenixTest.Playwright.Selector do
  @moduledoc false

  def concat(left, :none), do: left
  def concat(left, right), do: "#{left} >> #{right}"

  def unquote(:and)(left, :none), do: left
  def unquote(:and)(left, right), do: concat(left, "internal:and=#{Jason.encode!(right)}")
  defdelegate _and(left, right), to: __MODULE__, as: :and

  def text(nil, _opts), do: :none
  def text(text, opts), do: "internal:text=\"#{text}\"#{exact_suffix(opts)}"

  def label(nil, _opts), do: :none
  def label(label, opts), do: "internal:label=\"#{label}\"#{exact_suffix(opts)}"

  def at(nil), do: :none
  def at(at), do: "nth=#{at}"

  def css_or_locator(nil), do: :none
  def css_or_locator([]), do: :none
  def css_or_locator(selector) when is_binary(selector), do: css_or_locator([selector])
  def css_or_locator(selectors) when is_list(selectors), do: "css=#{Enum.join(selectors, ",")}"

  def css_or_locator(%PhoenixTest.Locators.Input{} = input) do
    attrs =
      input
      |> Map.take(~w(type value)a)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map_join("", fn {k, v} -> "[#{k}='#{v}']" end)

    input.label |> label(exact: true) |> _and(css_or_locator(attrs))
  end

  defp exact_suffix(opts) when is_list(opts), do: opts |> Keyword.get(:exact, false) |> exact_suffix()
  defp exact_suffix(true), do: "s"
  defp exact_suffix(false), do: "i"
end
