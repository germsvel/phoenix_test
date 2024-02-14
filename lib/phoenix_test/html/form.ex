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

  def validate_form_data!(form, form_data) do
    action = form["attributes"]["action"]
    unless action, do: raise(ArgumentError, "Expected form to have an action but found none")

    validate_form_fields!(form["fields"], form_data)
  end

  def validate_form_fields!(form_fields, form_data) do
    form_data
    |> Enum.each(fn
      {key, values} when is_map(values) ->
        Enum.each(values, fn {nested_key, nested_value} ->
          combined_key = "#{to_string(key)}[#{to_string(nested_key)}]"
          validate_form_fields!(form_fields, %{combined_key => nested_value})
        end)

      {key, _value} ->
        verify_field_presence!(form_fields, to_string(key))
    end)
  end

  defp verify_field_presence!([], expected_field) do
    raise ArgumentError, """
    Expected form to have #{inspect(expected_field)} form field, but found none.
    """
  end

  defp verify_field_presence!(form_fields, expected_field) do
    if Enum.all?(form_fields, fn field ->
         field["attributes"]["name"] != expected_field
       end) do
      raise ArgumentError, """
      Expected form to have #{inspect(expected_field)} form field, but found none.

      Found the following fields:

      #{format_form_fields_errors(form_fields)}
      """
    end
  end

  defp format_form_fields_errors(fields) do
    Enum.map_join(fields, "\n", &format_field_error/1)
  end

  defp format_field_error(field) do
    attrs = to_tuples(field["attributes"])
    Html.raw({field["tag"], attrs, []})
  end

  defp to_tuples(map) when is_map(map) do
    Enum.map(map, fn {_k, _v} = a -> a end)
  end
end
