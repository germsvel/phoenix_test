defmodule PhoenixTest.FieldHelpers do
  @moduledoc false

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.FormData
  alias PhoenixTest.Html

  # Computes the value to store in active_form for a field interaction.
  # For array-named fields (name ending in "[]"), values are accumulated/removed
  # from the existing list rather than replaced wholesale. This mirrors browser
  # behavior where each checkbox toggle adds/removes its value from the array.
  def next_field_value(session, form, field) do
    current_form_data = current_form_data(session, form)

    case {session.current_operation.name, field} do
      {:check, %{name: name, value: value}} ->
        if multiple_values_name?(name) do
          current_form_data
          |> FormData.get_data(name)
          |> List.wrap()
          |> Kernel.++([value])
          |> Enum.uniq()
        else
          value
        end

      {:uncheck, %{name: name, parsed: parsed} = current_field} ->
        if multiple_values_name?(name) do
          checked_value = Html.attribute(parsed, "value") || "on"

          current_form_data
          |> FormData.get_data(name)
          |> List.wrap()
          |> Enum.reject(&(&1 == checked_value))
        else
          current_field.value
        end

      {_, %{name: name, value: values}} ->
        if multiple_values_name?(name) and is_list(values) do
          current_form_data
          |> FormData.get_data(name)
          |> List.wrap()
          |> Kernel.++(values)
          |> Enum.uniq()
        else
          values
        end

      _ ->
        field.value
    end
  end

  def current_form_data(session, form) do
    if session.active_form.selector == form.selector do
      FormData.override(form.form_data, session.active_form.form_data)
    else
      form.form_data
    end
  end

  def active_form_for(active_form, form) do
    if active_form.selector == form.selector do
      active_form
    else
      ActiveForm.new(id: form.id, selector: form.selector)
    end
  end

  def multiple_values_name?(name) when is_binary(name) do
    String.ends_with?(name, "[]")
  end

  def multiple_values_name?(_name), do: false
end
