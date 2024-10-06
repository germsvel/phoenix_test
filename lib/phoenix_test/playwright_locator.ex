defmodule PhoenixTest.Playwright.Locator do
  @moduledoc false

  def concat(locator, :none), do: locator
  def concat(locator, string), do: Playwright.Locator.locator(locator, string)

  def unquote(:and)(locator, :none), do: locator

  def unquote(:and)(locator, string) do
    and_string = "internal:and=#{Jason.encode!(string)}"
    Playwright.Locator.locator(locator, and_string)
  end

  def text(nil, _opts), do: :none
  def text(text, opts), do: "internal:text=\"#{text}\"#{exact_suffix(opts)}"

  def label(nil, _opts), do: :none
  def label(label, opts), do: "internal:label=\"#{label}\"#{exact_suffix(opts)}"

  def at(nil), do: :none
  def at(at), do: "nth=#{at + 1}"

  def css(nil), do: :none
  def css([]), do: :none
  def css(selector) when is_binary(selector), do: css([selector])
  def css(selectors) when is_list(selectors), do: "css=#{Enum.join(selectors, ",")}"

  defp exact_suffix(opts) when is_list(opts), do: opts |> Keyword.get(:exact, false) |> exact_suffix()
  defp exact_suffix(true), do: "s"
  defp exact_suffix(false), do: "i"
end
