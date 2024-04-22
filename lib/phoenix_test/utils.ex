defmodule PhoenixTest.Utils do
  @moduledoc false

  def name_to_map(name, value) do
    parts = Regex.scan(~r/[\w|-]+/, name)

    parts
    |> List.flatten()
    |> Enum.reverse()
    |> Enum.reduce(value, fn key, acc ->
      %{key => acc}
    end)
  end

  def present?(term), do: !blank?(term)
  def blank?(term), do: term == nil || term == ""

  def stringify_keys_and_values(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end
end
