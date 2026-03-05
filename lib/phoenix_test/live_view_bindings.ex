defmodule PhoenixTest.LiveViewBindings do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Utils

  @type phx_click_action :: :render_click | :dispatch_change | :none

  @spec phx_click_action(LazyHTML.t()) :: phx_click_action()
  def phx_click_action(parsed_element) do
    parsed_element
    |> Html.attribute("phx-click")
    |> phx_click_action_from_attr()
  end

  def phx_click?(parsed_element) do
    phx_click_action(parsed_element) == :render_click
  end

  def phx_change?(parsed_element) do
    parsed_element
    |> Html.attribute("phx-change")
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
    |> any_render_click_compatible_js_command?()
  end

  defp valid_event_or_js_command?(value), do: Utils.present?(value)

  defp phx_click_action_from_attr("[" <> _ = js_command) do
    js_commands = Jason.decode!(js_command)

    cond do
      any_render_click_compatible_js_command?(js_commands) -> :render_click
      any_dispatch_change_js_command?(js_commands) -> :dispatch_change
      true -> :none
    end
  end

  defp phx_click_action_from_attr(value), do: if(Utils.present?(value), do: :render_click, else: :none)

  defp any_render_click_compatible_js_command?(js_commands) do
    Enum.any?(js_commands, &render_click_compatible_js_command?/1)
  end

  defp render_click_compatible_js_command?(["navigate", _opts]), do: true
  defp render_click_compatible_js_command?(["patch", _opts]), do: true
  defp render_click_compatible_js_command?(["push", _opts]), do: true
  defp render_click_compatible_js_command?([_command, _opts]), do: false

  defp any_dispatch_change_js_command?(js_commands) do
    Enum.any?(js_commands, &dispatch_change_js_command?/1)
  end

  defp dispatch_change_js_command?(["dispatch", %{"event" => "change"}]), do: true
  defp dispatch_change_js_command?([_command, _opts]), do: false

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
