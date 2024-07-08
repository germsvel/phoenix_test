defmodule PhoenixTest.Utils do
  @moduledoc false

  def present?(term), do: !blank?(term)
  def blank?(term), do: term == nil || term == ""

  def stringify_keys_and_values(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end
end
