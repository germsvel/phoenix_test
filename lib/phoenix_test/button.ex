defmodule PhoenixTest.Button do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Form
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[source_raw raw parsed id selector text name value]a

  def find!(html, selector, text) do
    html
    |> Query.find!(selector, text)
    |> build(html)
  end

  def find_first(html) do
    html
    |> Query.find("button")
    |> case do
      {:found, element} -> build(element, html)
      {:found_many, [element | _]} -> build(element, html)
      :not_found -> nil
    end
  end

  def build(parsed, source_raw) do
    button_html = Html.raw(parsed)
    id = Html.attribute(parsed, "id")
    name = Html.attribute(parsed, "name")
    value = Html.attribute(parsed, "value")
    selector = Element.build_selector(parsed)
    text = Html.text(parsed)

    %__MODULE__{
      source_raw: source_raw,
      raw: button_html,
      parsed: parsed,
      id: id,
      selector: selector,
      text: text,
      name: name,
      value: value
    }
  end

  def belongs_to_form?(button, html) do
    case Query.find_ancestor(html, "form", {button.selector, button.text}) do
      {:found, _} -> true
      _ -> false
    end
  end

  def phx_click?(button) do
    button.parsed
    |> Html.attribute("phx-click")
    |> Utils.present?()
  end

  def has_data_method?(button) do
    button.parsed
    |> Html.attribute("data-method")
    |> Utils.present?()
  end

  def to_form_data(button) do
    if button.name && button.value do
      Utils.name_to_map(button.name, button.value)
    else
      %{}
    end
  end

  def parent_form!(button) do
    Form.find_by_descendant!(button.source_raw, button)
  end
end
