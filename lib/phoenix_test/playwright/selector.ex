defmodule PhoenixTest.Playwright.Selector do
  @moduledoc """
  Playright supports different types of locators: CSS, XPath, internal.

  They can mixed and matched by chaining the together.

  Also, you can register [custom selector engines](https://playwright.dev/docs/extensibility#custom-selector-engines)
  that run right in the browser (Javascript).

  There is no official documentation, since this is considered Playwright internal.

  References:
  - https://playwright.dev/docs/other-locators
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/client/locator.ts
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/utils/isomorphic/locatorUtils.ts
  """

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

  def css(nil), do: :none
  def css([]), do: :none
  def css(selector) when is_binary(selector), do: css([selector])
  def css(selectors) when is_list(selectors), do: "css=#{Enum.join(selectors, ",")}"

  defp exact_suffix(opts) when is_list(opts), do: opts |> Keyword.get(:exact, false) |> exact_suffix()
  defp exact_suffix(true), do: "s"
  defp exact_suffix(false), do: "i"
end
