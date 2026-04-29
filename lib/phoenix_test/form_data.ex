defmodule PhoenixTest.FormData do
  @moduledoc false

  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Element.Select

  defstruct data: %{}, order: []

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
      new_data =
        Map.update(form_data.data, name, List.wrap(value), fn existing_value ->
          if value in existing_value do
            existing_value
          else
            existing_value ++ List.wrap(value)
          end
        end)

      %__MODULE__{form_data | data: new_data, order: append_order(form_data.order, name)}
    else
      %__MODULE__{
        form_data
        | data: Map.put(form_data.data, name, value),
          order: append_order(form_data.order, name)
      }
    end
  end

  def merge(%__MODULE__{} = fd1, %__MODULE__{} = fd2) do
    data =
      Map.merge(fd1.data, fd2.data, fn k, v1, v2 ->
        if allows_multiple_values?(k) do
          Enum.uniq(v1 ++ v2)
        else
          v2
        end
      end)

    %__MODULE__{data: data, order: merge_orders(fd1, fd2)}
  end

  def override(%__MODULE__{} = fd1, %__MODULE__{} = fd2) do
    %__MODULE__{
      data: Map.merge(fd1.data, fd2.data),
      order: merge_orders(fd1, fd2)
    }
  end

  def get_data(%__MODULE__{data: data}, name) do
    Map.get(data, name)
  end

  def put_data(%__MODULE__{} = form_data, name, value) when is_nil(name) or is_nil(value), do: form_data

  def put_data(%__MODULE__{} = form_data, name, value) do
    %__MODULE__{
      form_data
      | data: Map.put(form_data.data, name, value),
        order: append_order(form_data.order, name)
    }
  end

  defp allows_multiple_values?(field_name), do: String.ends_with?(field_name, "[]")

  def filter(%__MODULE__{} = form_data, fun) do
    data =
      form_data
      |> ordered_names()
      |> Enum.reduce(%{}, fn name, acc ->
        value = Map.get(form_data.data, name)

        if keep_data?(fun, name, value) do
          Map.put(acc, name, value)
        else
          acc
        end
      end)

    order =
      form_data
      |> ordered_names()
      |> Enum.filter(&Map.has_key?(data, &1))

    %__MODULE__{data: data, order: order}
  end

  def empty?(%__MODULE__{data: data}) do
    Enum.empty?(data)
  end

  def has_data?(%__MODULE__{data: data}, name, value) do
    field_data = Map.get(data, name, [])

    value == field_data or value in List.wrap(field_data)
  end

  def field_names(%__MODULE__{data: data}) do
    Map.keys(data)
  end

  def to_list(%__MODULE__{} = form_data) do
    form_data
    |> ordered_names()
    |> Enum.flat_map(fn name ->
      case Map.fetch!(form_data.data, name) do
        values when is_list(values) ->
          Enum.map(values, &{name, &1})

        value ->
          [{name, value}]
      end
    end)
  end

  defp append_order(order, name) do
    if name in order, do: order, else: order ++ [name]
  end

  defp merge_orders(%__MODULE__{} = fd1, %__MODULE__{} = fd2) do
    fd1
    |> ordered_names()
    |> Enum.concat(Enum.reject(ordered_names(fd2), &Map.has_key?(fd1.data, &1)))
  end

  defp ordered_names(%__MODULE__{data: data, order: order}) do
    order ++ Enum.reject(Map.keys(data), &(&1 in order))
  end

  defp keep_data?(fun, name, values) when is_list(values) do
    values
    |> Enum.map(&fun.(%{name: name, value: &1}))
    |> Enum.any?()
  end

  defp keep_data?(fun, name, value) do
    fun.(%{name: name, value: value})
  end
end
