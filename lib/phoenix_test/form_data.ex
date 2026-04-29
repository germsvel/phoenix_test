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
    add_data(form_data, field.name, values)
  end

  def add_data(form_data, data) when is_list(data) do
    Enum.reduce(data, form_data, fn new_data, acc ->
      add_data(acc, new_data)
    end)
  end

  def add_data(%__MODULE__{} = form_data, name, value) when is_nil(name) or is_nil(value), do: form_data

  def add_data(%__MODULE__{} = form_data, name, value) do
    if allows_multiple_values?(name) do
      existing_values = values_for_name(form_data.data, name)

      new_entries =
        value
        |> List.wrap()
        |> Enum.reject(&(&1 in existing_values))
        |> Enum.map(&{name, &1})

      %__MODULE__{form_data | data: form_data.data ++ new_entries}
    else
      put_data(form_data, name, value)
    end
  end

  def merge(%__MODULE__{} = form_data1, %__MODULE__{} = form_data2) do
    form_data2
    |> field_names()
    |> Enum.reduce(form_data1, fn name, acc ->
      if allows_multiple_values?(name) do
        add_data(acc, name, get_data(form_data2, name))
      else
        put_data(acc, name, get_data(form_data2, name))
      end
    end)
  end

  def override(%__MODULE__{} = form_data1, %__MODULE__{} = form_data2) do
    form_data2
    |> field_names()
    |> Enum.reduce(form_data1, fn name, acc ->
      put_data(acc, name, get_data(form_data2, name))
    end)
  end

  def get_data(%__MODULE__{data: data}, name) do
    values = values_for_name(data, name)

    cond do
      values == [] -> nil
      allows_multiple_values?(name) or length(values) > 1 -> values
      true -> hd(values)
    end
  end

  def put_data(%__MODULE__{} = form_data, name, value) when is_nil(name) or is_nil(value), do: form_data

  def put_data(%__MODULE__{} = form_data, name, value) do
    new_entries =
      value
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&{name, &1})

    %__MODULE__{form_data | data: replace_entries(form_data.data, name, new_entries)}
  end

  defp allows_multiple_values?(field_name), do: String.ends_with?(field_name, "[]")

  def filter(%__MODULE__{data: data}, fun) do
    %__MODULE__{
      data:
        Enum.filter(data, fn {name, value} ->
          fun.(%{name: name, value: value})
        end)
    }
  end

  def empty?(%__MODULE__{data: data}) do
    Enum.empty?(data)
  end

  def has_data?(%__MODULE__{} = form_data, name, value) do
    field_data = get_data(form_data, name)

    value == field_data or value in List.wrap(field_data)
  end

  def field_names(%__MODULE__{data: data}) do
    data
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
  end

  def to_list(%__MODULE__{data: data}), do: data

  defp replace_entries(data, name, new_entries) do
    case Enum.find_index(data, fn {n, _} -> n == name end) do
      nil ->
        data ++ new_entries

      first_index ->
        filtered_data = Enum.reject(data, fn {n, _} -> n == name end)
        {before, after_entries} = Enum.split(filtered_data, first_index)
        before ++ new_entries ++ after_entries
    end
  end

  defp values_for_name(data, name) do
    data
    |> Enum.filter(fn {n, _} -> n == name end)
    |> Enum.map(fn {_, v} -> v end)
  end
end
