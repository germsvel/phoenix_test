defmodule PhoenixTest.Utils do
  @moduledoc false

  def present?(term), do: !blank?(term)
  def blank?(term), do: term == nil || term == ""

  def stringify_keys_and_values(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_list(v) ->
        {to_string(k), Enum.map(v, &to_string/1)}

      {k, v} ->
        {to_string(k), to_string(v)}
    end)
  end
end
