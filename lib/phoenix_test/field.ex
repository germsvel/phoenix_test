defmodule PhoenixTest.Field do
  @moduledoc false

  @enforce_keys ~w[html label id name value]a
  defstruct ~w[html label id name value]a

  alias PhoenixTest.Html
  alias PhoenixTest.Form
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  def find_input!(html, label) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value")

    %__MODULE__{
      html: html,
      label: label,
      id: id,
      name: name,
      value: value
    }
  end

  def find_select_option!(html, label, option) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    option = Query.find!(Html.raw(field), "option", option)
    value = Html.attribute(option, "value")

    %__MODULE__{
      html: html,
      label: label,
      id: id,
      name: name,
      value: value
    }
  end

  def find_checkbox!(html, label) do
    source = Query.find_by_label!(html, label)
    id = Html.attribute(source, "id")
    name = Html.attribute(source, "name")
    value = Html.attribute(source, "value") || "on"

    %__MODULE__{
      html: html,
      label: label,
      id: id,
      name: name,
      value: value
    }
  end

  def find_hidden_uncheckbox!(html, label) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    hidden_input = Query.find!(html, "input[type='hidden'][name=#{name}]")
    value = Html.attribute(hidden_input, "value")

    %__MODULE__{
      html: html,
      label: label,
      id: id,
      name: name,
      value: value
    }
  end

  def to_form_data(field) do
    Utils.name_to_map(field.name, field.value)
  end

  def parent_form(field) do
    Form.find_by_descendant!(field.html, field)
  end
end
