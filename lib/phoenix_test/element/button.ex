defmodule PhoenixTest.Element.Button do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Form
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[parsed id selector text type name value form_id]a

  def find!(html, selector, text) do
    html
    |> Query.find!(selector, text)
    |> build()
    |> keep_best_selector(selector)
  end

  defp keep_best_selector(button, provided_selector) do
    case provided_selector do
      "button" ->
        button

      anything_better_than_button ->
        %{button | selector: anything_better_than_button}
    end
  end

  def find_first(html) do
    html
    |> Query.find("button")
    |> case do
      {:found, element} -> build(element)
      {:found_many, elements} -> elements |> Enum.at(0) |> build()
      :not_found -> nil
    end
  end

  def build(parsed) do
    id = Html.attribute(parsed, "id")
    name = Html.attribute(parsed, "name")
    value = Html.attribute(parsed, "value") || if name, do: ""
    selector = Element.build_selector(parsed)
    text = Html.element_text(parsed)
    type = Html.attribute(parsed, "type") || "submit"
    form_id = Html.attribute(parsed, "form")

    %__MODULE__{
      parsed: parsed,
      id: id,
      selector: selector,
      text: text,
      type: type,
      name: name,
      value: value,
      form_id: form_id
    }
  end

  def belongs_to_form?(%__MODULE__{} = button, html) do
    !!button.form_id || (button.type == "submit" && belongs_to_ancestor_form?(button, html))
  end

  defp belongs_to_ancestor_form?(button, html) do
    case Query.find_ancestor(html, "form", {button.selector, button.text}) do
      {:found, _} -> true
      _ -> false
    end
  end

  def phx_click?(%__MODULE__{} = button), do: LiveViewBindings.phx_click?(button.parsed)

  def has_data_method?(%__MODULE__{} = button) do
    button.parsed
    |> Html.attribute("data-method")
    |> Utils.present?()
  end

  def parent_form!(%__MODULE__{} = button, html) do
    if button.form_id do
      Form.find!(html, "[id=#{inspect(button.form_id)}]")
    else
      Form.find_by_descendant!(html, button)
    end
  end
end
