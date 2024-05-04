defmodule PhoenixTest.Field do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  @enforce_keys ~w[source_raw label id name value selector]a
  defstruct ~w[source_raw label id name value selector]a

  def find_input!(html, label) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value")

    %__MODULE__{
      source_raw: html,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_select_option!(html, label, option) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    multiple = Html.attribute(field, "multiple") == "multiple"

    value =
      case {multiple, option} do
        {true, [_ | _]} ->
          Enum.map(option, fn opt ->
            opt = Query.find!(Html.raw(field), "option", opt)
            Html.attribute(opt, "value")
          end)

        {true, _} ->
          option = Query.find!(Html.raw(field), "option", option)
          [Html.attribute(option, "value")]

        {false, [_ | _]} ->
          msg = """
          Could not find a select with a "multiple" attribute set.

          Found the following select:

          #{Html.raw(field)}
          """

          raise ArgumentError, msg

        {false, _} ->
          option = Query.find!(Html.raw(field), "option", option)
          Html.attribute(option, "value")
      end

    %__MODULE__{
      source_raw: html,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_checkbox!(html, label) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value") || "on"

    %__MODULE__{
      source_raw: html,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_hidden_uncheckbox!(html, label) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    hidden_input = Query.find!(html, "input[type='hidden'][name=#{name}]")
    value = Html.attribute(hidden_input, "value")

    %__MODULE__{
      source_raw: html,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def to_form_data(field) do
    Utils.name_to_map(field.name, field.value)
  end

  def parent_form!(field) do
    Form.find_by_descendant!(field.source_raw, field)
  end
end
