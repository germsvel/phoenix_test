defmodule PhoenixTest.Locators do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def input(opts) do
    type = Keyword.get(opts, :type)
    label = Keyword.get(opts, :label)
    value = Keyword.get(opts, :value)

    {:input, %{type: type, label: label, value: value}}
  end

  def button(opts) do
    text = Keyword.get(opts, :text)
    roles = ~w|button input[type="button"] input[type="image"] input[type="reset"] input[type="submit"]|

    {:button, %{text: text, roles: roles}}
  end

  def role_selectors({:button, data}) do
    %{text: text, roles: roles} = data

    Enum.map(roles, fn
      "button" -> {"button", text}
      role -> role <> "[value=#{inspect(text)}]"
    end)
  end

  def compile({:input, attrs}, html) do
    {label, attrs} = Map.pop(attrs, :label)

    element = Query.find_by_label!(html, "input:not([type='hidden'])", label, exact: true)
    id = Html.attribute(element, "id")

    existing_attrs =
      attrs
      |> Enum.filter(fn {_k, v} -> v != nil end)
      |> Enum.reduce("", fn {k, v}, acc ->
        acc <> "[#{k}=#{inspect(v)}]"
      end)

    "input[id=#{inspect(id)}]" <> existing_attrs
  end
end
