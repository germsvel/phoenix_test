defmodule PhoenixTest.Element.Field do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query

  @enforce_keys ~w[parsed label id name value selector]a
  defstruct ~w[parsed label id name value selector]a

  def find_input(html, input_selectors, label, opts) do
    with {:ok, field} <- Query.find_by_label(html, input_selectors, label, opts) do
      {:ok, build(field, label, Html.attribute(field, "value"))}
    end
  end

  def find_checkbox(html, input_selector, label, opts) do
    with {:ok, field} <- Query.find_by_label(html, input_selector, label, opts) do
      {:ok, build(field, label, Html.attribute(field, "value") || "on")}
    end
  end

  def find_hidden_uncheckbox(html, input_selector, label, opts) do
    with {:ok, field} <- Query.find_by_label(html, input_selector, label, opts),
         name = Html.attribute(field, "name"),
         {:ok, hidden_input} <- Query.find(html, "input[type='hidden'][name='#{name}']") do
      {:ok, build(field, label, Html.attribute(hidden_input, "value"))}
    end
  end

  def parent_form(field, html), do: Form.find_by_descendant(html, field)
  def phx_click?(field), do: LiveViewBindings.phx_click?(field.parsed)
  def phx_value?(field), do: LiveViewBindings.phx_value?(field.parsed)
  def phx_change?(field), do: LiveViewBindings.phx_change?(field.parsed)

  def belongs_to_form?(field, html), do: Query.has_ancestor?(html, "form", field)

  def validate_name!(field) do
    if field.name == nil do
      raise ArgumentError, """
      Field is missing a `name` attribute:

      #{Html.raw(field.parsed)}
      """
    end
  end

  defp build(field, label, value) do
    %__MODULE__{
      parsed: field,
      label: label,
      id: Html.attribute(field, "id"),
      name: Html.attribute(field, "name"),
      value: value,
      selector: Element.build_selector(field)
    }
  end
end
