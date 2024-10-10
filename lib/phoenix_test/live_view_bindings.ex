defmodule PhoenixTest.LiveViewBindings do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Utils

  def phx_click?(parsed_element) do
    parsed_element
    |> Html.attribute("phx-click")
    |> valid_event_or_js_command?()
  end

  defp valid_event_or_js_command?("[" <> _ = js_command), do: valid_js_command?(js_command)
  defp valid_event_or_js_command?(value), do: Utils.present?(value)

  @commands_live_view_test_handles ~w[push navigate]
  defp valid_js_command?(js_command) do
    String.contains?(js_command, @commands_live_view_test_handles)
  end
end
