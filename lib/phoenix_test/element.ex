defmodule PhoenixTest.Element do
  @moduledoc false

  def build_selector({tag, attributes, _}) do
    Enum.reduce_while(attributes, tag, fn
      {"id", id}, _ when is_binary(id) -> {:halt, "[id=#{inspect(id)}]"}
      {"phx-" <> _rest, _}, acc -> {:cont, acc}
      {"class", _}, acc -> {:cont, acc}
      {k, v}, acc -> {:cont, acc <> "[#{k}=#{inspect(v)}]"}
    end)
  end
end
