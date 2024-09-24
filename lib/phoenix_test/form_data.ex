defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Html

  def to_form_data!(%{value: values} = field) when is_list(values) do
    Enum.map(values, &{field.name, &1})
  end

  def to_form_data!(field) do
    validate!(field)
    [{field.name, field.value}]
  end

  defp validate!(field) do
    if field.name == nil do
      raise ArgumentError, """
      Field is missing a `name` attribute:

      #{Html.raw(field.parsed)}
      """
    end
  end
end
