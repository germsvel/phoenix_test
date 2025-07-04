defmodule PhoenixTest.Utils do
  @moduledoc false

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

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

  def current_endpoint() do
    current_app = Mix.Project.config()[:app]

    if is_nil(current_app) do
      raise "no :app set in Mix project config"
    end

    Application.fetch_env(:phoenix_test, :endpoints)
    |> case do
      {:ok, endpoints} -> 
        Access.fetch(endpoints, current_app)
        |> case do
          {:ok, endpoint} -> endpoint
          :error -> raise "no endpoint set for #{current_app} in config"
        end

      :error ->
        case @endpoint do
          nil -> raise "no endpoint set in config"
          _ -> @endpoint
        end
    end
  end
end
