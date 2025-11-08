defmodule PhoenixTest.LiveViewBindings do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Utils

  def phx_click?(parsed_element) do
    parsed_element
    |> Html.attribute("phx-click")
    |> valid_event_or_js_command?()
  end

  def phx_value?(parsed_element) do
    cond do
      any_phx_value_attributes?(parsed_element) -> true
      phx_click_command_has_value?(parsed_element) -> true
      true -> false
    end
  end

  def phx_session?(parsed_element) do
    parsed_element
    |> Html.attribute("data-phx-session")
    |> Utils.present?()
  end

  defp valid_event_or_js_command?("[" <> _ = js_command) do
    js_command
    |> Jason.decode!()
    |> any_valid_js_command?()
  end

  defp valid_event_or_js_command?(value), do: Utils.present?(value)

  defp any_valid_js_command?(js_commands) do
    Enum.any?(js_commands, &valid_js_command?/1)
  end

  defp valid_js_command?(["navigate", _opts]), do: true
  defp valid_js_command?(["patch", _opts]), do: true
  defp valid_js_command?(["push", _opts]), do: true
  defp valid_js_command?([_command, _opts]), do: false

  defp any_phx_value_attributes?(%LazyHTML{} = element) do
    element
    |> Html.attributes()
    |> Enum.any?(fn {key, _value} -> String.starts_with?(key, "phx-value-") end)
  end

  defp phx_click_command_has_value?(%LazyHTML{} = element) do
    element
    |> Html.attribute("phx-click")
    |> phx_click_command_has_value?()
  end

  defp phx_click_command_has_value?("[" <> _ = js_command) do
    js_command
    |> Jason.decode!()
    |> Enum.find(&match?(["push", _opts], &1))
    |> case do
      ["push", opts] -> Map.has_key?(opts, "value")
      _ -> false
    end
  end

  defp phx_click_command_has_value?(_), do: false
end
