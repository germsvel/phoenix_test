defmodule PhoenixTest.FormData do
  @moduledoc false
  def to_form_data(%{value: values} = field) when is_list(values) do
    Enum.map(values, &{field.name, &1})
  end

  def to_form_data(field) do
    [{field.name, field.value}]
  end
end
