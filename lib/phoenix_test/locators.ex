defmodule PhoenixTest.Locators do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  defmodule Button do
    @moduledoc false
    defstruct ~w[text roles]a
  end

  defmodule Input do
    @moduledoc false
    defstruct ~w[type label value]a
  end

  def input(opts) do
    type = Keyword.get(opts, :type)
    label = Keyword.get(opts, :label)
    value = Keyword.get(opts, :value)

    %Input{type: type, label: label, value: value}
  end

  def button(opts) do
    text = Keyword.get(opts, :text)
    roles = ~w|button input[type="button"] input[type="image"] input[type="reset"] input[type="submit"]|

    %Button{text: text, roles: roles}
  end

  def role_selectors(%Button{} = button) do
    %Button{text: text, roles: roles} = button

    Enum.map(roles, fn
      "button" -> {"button", text}
      role -> role <> "[value=#{inspect(text)}]"
    end)
  end

  def compile(%Input{} = input, html) do
    label = input.label
    attrs = Map.take(input, [:type, :value])

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
