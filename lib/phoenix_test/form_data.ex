defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select

  defstruct data: %{}

  def new, do: %__MODULE__{}

  def add_data(%__MODULE__{} = form_data, {name, value}) do
    add_data(form_data, name, value)
  end

  def add_data(%__MODULE__{} = form_data, %Button{} = button) do
    add_data(form_data, button.name, button.value)
  end

  def add_data(%__MODULE__{} = form_data, %Field{} = field) do
    add_data(form_data, field.name, field.value)
  end

  def add_data(%__MODULE__{} = form_data, %Select{value: values} = field) when is_list(values) do
    add_data(form_data, field.name, values)
  end

  def add_data(form_data, data) when is_list(data) do
    Enum.reduce(data, form_data, fn new_data, acc ->
      add_data(acc, new_data)
    end)
  end

  def add_data(%__MODULE__{} = form_data, name, value) when is_nil(name) or is_nil(value), do: form_data

  def add_data(%__MODULE__{} = form_data, name, value) do
    if String.ends_with?(name, "[]") do
      new_data =
        Map.update(form_data.data, name, List.wrap(value), fn existing_value ->
          if value in existing_value do
            existing_value
          else
            [value | existing_value]
          end
        end)

      %__MODULE__{form_data | data: new_data}
    else
      %__MODULE__{form_data | data: Map.put(form_data.data, name, value)}
    end
  end

  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  def filter(%__MODULE__{data: data}, fun) do
    data =
      data
      |> Enum.filter(fn {name, value} -> fun.(%{name: name, value: value}) end)
      |> Map.new()

    %__MODULE__{data: data}
  end

  def empty?(%__MODULE__{data: data}) do
    Enum.empty?(data)
  end

  def has_data?(%__MODULE__{data: data}, name, value) do
    field_data = Map.get(data, name, [])
    value == field_data or value in field_data
  end

  def to_list(%__MODULE__{data: data}) do
    data
    |> Enum.map(fn
      {key, values} when is_list(values) ->
        Enum.map(values, &{key, &1})

      {_key, _value} = field ->
        field
    end)
    |> List.flatten()
  end
end
