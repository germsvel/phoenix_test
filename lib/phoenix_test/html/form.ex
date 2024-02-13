defmodule PhoenixTest.Html.Form do
  @moduledoc false

  alias PhoenixTest.Html

  def build({"form", attrs, fields}) do
    %{}
    |> Map.put("attributes", build_attributes(attrs))
    |> Map.put("fields", build_fields(fields))
  end

  defp build_attributes(attrs) do
    attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  defp build_fields(fields) do
    inputs = fields |> Html.all("input")
    selects = fields |> Html.all("select")
    textareas = fields |> Html.all("textarea")

    Enum.concat([inputs, selects, textareas])
    |> Enum.map(&build_field/1)
  end

  defp build_field({"select", attrs, options}) do
    %{"tag" => "select"}
    |> Map.put("attributes", build_attributes(attrs))
    |> Map.put("options", build_options(options))
  end

  defp build_field({tag, attrs, contents}) do
    %{"tag" => tag}
    |> Map.put("attributes", build_attributes(attrs))
    |> Map.put("content", Enum.join(contents, " "))
  end

  defp build_options(options) do
    Enum.map(options, &build_field/1)
  end
end
