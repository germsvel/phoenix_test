defmodule PhoenixTest.Field do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  @enforce_keys ~w[source_raw parsed label id name value selector]a
  defstruct ~w[source_raw parsed label id name value selector]a

  def find_input!(html, input_selectors, label, opts) do
    field = Query.find_by_label!(html, input_selectors, label, opts)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value")

    %__MODULE__{
      source_raw: html,
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_checkbox!(html, input_selector, label, opts) do
    field = Query.find_by_label!(html, input_selector, label, opts)

    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")
    value = Html.attribute(field, "value") || "on"

    %__MODULE__{
      source_raw: html,
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def find_hidden_uncheckbox!(html, input_selector, label, opts) do
    field = Query.find_by_label!(html, input_selector, label, opts)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    hidden_input = Query.find!(html, "input[type='hidden'][name='#{name}']")
    value = Html.attribute(hidden_input, "value")

    %__MODULE__{
      source_raw: html,
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: value,
      selector: Element.build_selector(field)
    }
  end

  def parent_form!(field) do
    Form.find_by_descendant!(field.source_raw, field)
  end

  def phx_click?(field) do
    field.parsed
    |> Html.attribute("phx-click")
    |> Utils.present?()
  end

  def belongs_to_form?(field) do
    case Query.find_ancestor(field.source_raw, "form", field.selector) do
      {:found, _} -> true
      _ -> false
    end
  end

  def validate_name!(field) do
    if field.name == nil do
      raise ArgumentError, """
      Field is missing a `name` attribute:

      #{Html.raw(field.parsed)}
      """
    end
  end
end
