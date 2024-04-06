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
end
