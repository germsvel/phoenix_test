defmodule PhoenixTest.Html.Form do
  @moduledoc false

  def parse({"form", attrs, fields}) do
    %{}
    |> put_attributes(attrs)
    |> Map.put("fields", build_fields(fields))
  end

  defp put_attributes(form, attrs) do
    attrs
    |> Enum.reduce(form, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  defp build_fields(fields) do
    inputs = fields |> Floki.find("input")
    selects = fields |> Floki.find("select")
    textareas = fields |> Floki.find("textarea")

    Enum.concat([inputs, selects, textareas])
    |> Enum.map(&create_field/1)
  end

  defp create_field({"select", attrs, options}) do
    %{"type" => "select"}
    |> put_attributes(attrs)
    |> Map.put("options", create_options(options))
  end

  defp create_field({type, attrs, contents}) do
    %{"type" => type}
    |> put_attributes(attrs)
    |> Map.put("content", Enum.join(contents, " "))
  end

  defp create_options(options) do
    Enum.map(options, &create_field/1)
  end
end
