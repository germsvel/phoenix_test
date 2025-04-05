defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select

  defstruct data: []

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
    new_data = Enum.map(values, &{field.name, &1})
    add_data(form_data, new_data)
  end

  def add_data(form_data, []), do: form_data

  def add_data(form_data, data) when is_list(data) do
    Enum.reduce(data, form_data, fn new_data, acc ->
      add_data(acc, new_data)
    end)
  end

  def add_data(%__MODULE__{} = form_data, name, value) do
    if name && value do
      new_data = format_data(name, value)
      %__MODULE__{form_data | data: form_data.data ++ new_data}
    else
      form_data
    end
  end

  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: data1 ++ data2}
  end

  def filter(%__MODULE__{data: data}, fun) do
    data =
      Enum.filter(data, fn {name, value} -> fun.(%{name: name, value: value}) end)

    %__MODULE__{data: data}
  end

  def empty?(%__MODULE__{data: data}) do
    Enum.empty?(data)
  end

  def has_data?(%__MODULE__{data: data}, name, value) do
    {name, value} in data
  end

  def to_list(%__MODULE__{data: data}) do
    deduplicate_preserving_order(data)
  end

  defp deduplicate_preserving_order(data) do
    data
    |> Enum.reverse()
    |> Enum.uniq_by(fn {key, value} ->
      if String.ends_with?(key, "[]") do
        {key, value}
      else
        key
      end
    end)
    |> Enum.reverse()
  end

  defp format_data(name, values) when is_binary(name) and is_list(values) do
    Enum.map(values, &{name, &1})
  end

  defp format_data(name, value) when is_binary(name) do
    [{name, value}]
  end
end
