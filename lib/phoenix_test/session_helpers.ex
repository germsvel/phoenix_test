defmodule PhoenixTest.SessionHelpers do
  @moduledoc false
  def within(session, selector, fun) when is_binary(selector) and is_function(fun, 1) do
    session
    |> Map.update!(:within, &scope_selector(&1, selector))
    |> fun.()
    |> Map.put(:within, :none)
  end

  def scope_selector(:none, selector), do: selector

  def scope_selector(within, selector) when is_binary(within) do
    within <> " " <> selector
  end
end
