defmodule PhoenixTest.Element do
  @moduledoc false
  import PhoenixTest.SessionHelpers, only: [within_selector: 2]

  alias PhoenixTest.Html

  def build_selector(%LazyHTML{} = html, within) do
    html
    |> Html.element()
    |> build_selector(within)
  end

  def build_selector({tag, attributes, _}, within) do
    attributes
    |> Enum.reduce_while(tag, fn
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
    |> then(&within_selector(within, &1))
  end

  defp encoded_live_view_js?(value) do
    value =~ "[["
  end

  def selector_has_id?(selector, id) when is_binary(selector) and is_binary(id) do
    Enum.any?(["[id='#{id}'", ~s|[id="id"]|, "##{id}"], &String.contains?(selector, &1))
  end
end
