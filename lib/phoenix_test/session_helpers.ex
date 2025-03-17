defmodule PhoenixTest.SessionHelpers do
  @moduledoc false
  def within(session, selector, fun) when is_binary(selector) and is_function(fun, 1) do
    session
    |> Map.update!(:within, fn
      :none -> selector
      parent when is_binary(parent) -> parent <> " " <> selector
    end)
    |> fun.()
    |> Map.put(:within, :none)
  end
end
