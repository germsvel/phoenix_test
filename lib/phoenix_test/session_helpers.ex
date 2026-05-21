defmodule PhoenixTest.SessionHelpers do
  @moduledoc false
  def within(session, selector, fun) when is_binary(selector) and is_function(fun, 1) do
    original_within = session.within

    session
    |> Map.update!(:within, &scope_selector(selector, &1))
    |> fun.()
    |> Map.put(:within, original_within)
  end

  def scope_selector(selector, :none), do: selector

  def scope_selector(selector, within) when is_binary(within) do
    within <> " " <> selector
  end
end
