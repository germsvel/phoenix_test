defmodule PhoenixTest.FormPayload do
  @moduledoc false

  def new(form_data) when is_list(form_data) do
    form_data
    |> Enum.map_join("&", fn {key, value} ->
      "#{URI.encode_www_form(key)}=#{if(value, do: URI.encode_www_form(value))}"
    end)
    |> Plug.Conn.Query.decode()
  end

  def add_form_data(payload, form_data) when is_map(payload) and is_list(form_data) do
    Enum.reduce(form_data, payload, fn {name, value}, acc ->
      with_placeholder = Plug.Conn.Query.decode("#{URI.encode_www_form(name)}=placeholder")
      put_at_placeholder(acc, with_placeholder, value)
    end)
  end

  defp put_at_placeholder(_, "placeholder", value), do: value
  defp put_at_placeholder(list, ["placeholder"], value), do: (list || []) ++ [value]

  defp put_at_placeholder(map, with_placeholder, value) do
    map = map || %{}
    [{key, placeholder_value}] = Map.to_list(with_placeholder)
    Map.put(map, key, put_at_placeholder(map[key], placeholder_value, value))
  end
end
