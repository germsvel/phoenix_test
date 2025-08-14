defmodule PhoenixTest.LiveViewBindings do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Utils

  def phx_click?(parsed_element) do
    parsed_element
    |> Html.attribute("phx-click")
    |> valid_event_or_js_command?()
  end

  def phx_value?({_element, attributes, _children}) do
    Enum.any?(attributes, fn {key, _value} -> String.starts_with?(key, "phx-value-") end)
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
end
