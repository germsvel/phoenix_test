defmodule PhoenixTest.Selectors do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def input(opts) do
    type = Keyword.get(opts, :type)
    label = Keyword.get(opts, :label)
    value = Keyword.get(opts, :value)

    {:input, %{type: type, label: label, value: value}}
  end

  def compile({:input, attrs}, html) do
    {label, attrs} = Map.pop(attrs, :label)

    element = Query.find_by_label!(html, label)
    id = Html.attribute(element, "id")

    existing_attrs =
      attrs
      |> Enum.filter(fn {_k, v} -> v != nil end)
      |> Enum.reduce("", fn {k, v}, acc ->
        acc <> "[#{k}=#{inspect(v)}]"
      end)

    "input##{id}" <> existing_attrs
  end
end
