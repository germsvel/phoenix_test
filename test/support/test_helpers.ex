defmodule PhoenixTest.TestHelpers do
  @moduledoc false

  @doc """
  Converts a multi-line string into a whitespace-forgiving regex
  """
  def ignore_whitespace(string) do
    string
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map_join("\n", fn s -> "\\s*" <> s <> "\\s*" end)
    |> Regex.compile!([:dotall])
  end
end
