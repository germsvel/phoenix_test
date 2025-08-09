defmodule PhoenixTest.SessionHelpers do
  @moduledoc false
  def within(session, selector, fun) when is_binary(selector) and is_function(fun, 1) do
    session
    |> Map.update!(:within, fn
      nil -> selector
      parent when is_binary(parent) -> within_selector(parent, selector)
    end)
    |> fun.()
    |> Map.put(:within, nil)
  end

  def within_selector(%{within: parent} = _session, selector) when is_binary(parent) and is_binary(selector) do
    within_selector(parent, selector)
  end

  def within_selector(%{within: parent} = _session, selectors) when is_binary(parent) and is_list(selectors) do
    Enum.map(selectors, &within_selector(parent, &1))
  end

  def within_selector(%{} = _session, selector), do: selector

  def within_selector(nil, selector) when is_binary(selector), do: selector

  def within_selector(parent, selector) when is_binary(parent) and is_binary(selector) do
    parent <> " " <> selector
  end
end
