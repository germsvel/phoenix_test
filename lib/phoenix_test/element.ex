defmodule PhoenixTest.Element do
  @moduledoc false

  def build_selector({tag, attributes, _}) do
    Enum.reduce_while(attributes, tag, fn
      {"id", id}, _ when is_binary(id) ->
        {:halt, "[id=#{inspect(id)}]"}

      {"phx-" <> _rest = phx_attr, value}, acc ->
        if encoded_live_view_js?(value) do
          {:cont, acc}
        else
          {:cont, acc <> "[#{phx_attr}=#{inspect(value)}]"}
        end

      {"class", _}, acc ->
        {:cont, acc}

      {k, v}, acc ->
        {:cont, acc <> "[#{k}=#{inspect(v)}]"}
    end)
  end

  defp encoded_live_view_js?(value) do
    value =~ "[["
  end

  def selector_has_id?(selector) when is_binary(selector) do
    String.contains?(selector, ["[id=", "#"])
  end
end
