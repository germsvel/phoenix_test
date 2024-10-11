defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select

  def new, do: []

  def add_data(data, new_data) when is_list(new_data) do
    data ++ new_data
  end

  def empty?(data) when is_list(data) do
    Enum.empty?(data)
  end

  def to_form_data(%Button{} = button) do
    if button.name && button.value do
      [{button.name, button.value}]
    else
      []
    end
  end

  def to_form_data(%Select{value: values} = field) when is_list(values) do
    Enum.map(values, &{field.name, &1})
  end

  def to_form_data(%Field{} = field) do
    [{field.name, field.value}]
  end

  def to_form_data(name, values) when is_binary(name) and is_list(values) do
    Enum.map(values, &{name, &1})
  end

  def to_form_data(name, value) when is_binary(name) do
    [{name, value}]
  end

  def to_form_data(nil, _value), do: []

  def has_data?(data, name, value) when is_list(data) do
    {name, value} in data
  end
end
