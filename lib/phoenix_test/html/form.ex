defmodule PhoenixTest.Html.Form do
  @moduledoc false

  alias PhoenixTest.Html

  @doc """
  Builds an HTML form structure.

  This function takes a tuple representation of a form and converts it into a map structure.

  ## Parameters

  - `{"form", attrs, fields}`: Tuple representing the form structure.
    - `attrs`: A map containing form attributes (e.g., action, method).
    - `fields`: A list of tuples representing form fields.

  ## Returns

  A map representing the HTML form structure with the following keys:
  - `"attributes"`: A map containing form attributes.
  - `"fields"`: A list of maps representing form fields.
  - `"operative_method"`: A string representing the form's method, extracted from hidden input or defaulting to "get".
  """
  def build({"form", attrs, fields}) do
    %{}
    |> Map.put("attributes", build_attributes(attrs))
    |> Map.put("fields", build_fields(fields))
    |> put_operative_method()
  end

  defp build_attributes(attrs) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end

  defp build_fields(fields) do
    inputs = Html.all(fields, "input")
    selects = Html.all(fields, "select")
    textareas = Html.all(fields, "textarea")

    [inputs, selects, textareas]
    |> Enum.concat()
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

  defp put_operative_method(form) do
    method = hidden_input_method_value(form["fields"]) || form["attributes"]["method"] || "get"

    Map.put(form, "operative_method", method)
  end

  defp hidden_input_method_value(fields) do
    fields
    |> Enum.find(:no_method_input, fn field ->
      field["tag"] == "input" && field["attributes"]["name"] == "_method"
    end)
    |> case do
      :no_method_input -> nil
      field -> field["attributes"]["value"]
    end
  end

  @doc """
  Validates the form data against the expected structure of a form.

  This function ensures that the provided form data matches the structure expected by the form.
  It checks for the presence of required fields and raises an error if the structure is not as expected.

  ## Parameters

  - `form`: A map representing the HTML form structure.
  - `form_data`: A map containing the form data to be validated.

  ## Raises

  Raises `ArgumentError` if the form data does not match the expected structure.
  """
  def validate_form_data!(form, form_data) do
    action = get_in(form, ["attributes", "action"])
    unless action, do: raise(ArgumentError, "Expected form to have an action but found none")

    validate_form_fields!(form["fields"], form_data)
  end

  @doc """
  Validates the form fields against the provided form data.

  This function checks if the provided form data matches the expected structure of the form fields.
  It recursively validates nested maps within the form data and raises an error if the structure is not as expected.

  ## Parameters

  - `form_fields`: A list representing the HTML form fields.
  - `form_data`: A map containing the form data to be validated.

  ## Raises

  Raises `ArgumentError` if the form data does not match the expected structure.
  """
  def validate_form_fields!(form_fields, form_data) do
    Enum.each(form_data, fn
      {key, values} when is_map(values) ->
        Enum.each(values, fn {nested_key, nested_value} ->
          combined_key = "#{to_string(key)}[#{to_string(nested_key)}]"
          validate_form_fields!(form_fields, %{combined_key => nested_value})
        end)

      {key, values} when is_list(values) ->
        verify_field_presence!(form_fields, to_string(key) <> "[]")

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
