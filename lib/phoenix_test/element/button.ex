defmodule PhoenixTest.Element.Button do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[source_raw raw parsed id selector text name value form_id]a

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
      {:found_many, elements} -> elements |> Enum.at(0) |> build(html)
      :not_found -> nil
    end
  end

  def build(parsed, source_raw) do
    button_html = Html.raw(parsed)
    id = Html.attribute(parsed, "id")
    name = Html.attribute(parsed, "name")
    value = Html.attribute(parsed, "value") || if name, do: ""
    selector = Element.build_selector(parsed)
    text = Html.inner_text(parsed)
    form_id = Html.attribute(parsed, "form")

    %__MODULE__{
      source_raw: source_raw,
      raw: button_html,
      parsed: parsed,
      id: id,
      selector: selector,
      text: text,
      name: name,
      value: value,
      form_id: form_id
    }
  end

  def belongs_to_form?(button) do
    !!button.form_id || belongs_to_ancestor_form?(button)
  end

  defp belongs_to_ancestor_form?(button) do
    case Query.find_ancestor(button.source_raw, "form", {button.selector, button.text}) do
      {:found, _} -> true
      _ -> false
    end
  end

  def phx_click?(button), do: LiveViewBindings.phx_click?(button.parsed)

  def has_data_method?(button) do
    button.parsed
    |> Html.attribute("data-method")
    |> Utils.present?()
  end

  def parent_form!(button) do
    if button.form_id do
      Form.find!(button.source_raw, "[id=#{inspect(button.form_id)}]")
    else
      Form.find_by_descendant!(button.source_raw, button)
    end
  end
end
