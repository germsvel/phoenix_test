defmodule PhoenixTest.TestHelpers do
  @moduledoc false

  require ExUnit.Case

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

  defmacro test_also_with_playwright(message, var \\ quote(do: _), contents) do
    quote location: :keep do
      tags = Module.get_attribute(__MODULE__, :tag)
      ExUnit.Case.test(unquote(message), unquote(var), unquote(contents))

      for tag <- tags, do: @tag(tag)
      @tag :playwright
      ExUnit.Case.test(unquote(message) <> " (JS)", unquote(var), unquote(contents))
    end
  end
end
