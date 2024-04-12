defmodule PhoenixTest.Button do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[raw parsed id selector text name value]a

  def find!(html, selector, text) do
    button = Query.find!(html, selector, text)
    button_html = Html.raw(button)
    id = Html.attribute(button, "id")
    name = Html.attribute(button, "name")
    value = Html.attribute(button, "value")

    %__MODULE__{
      raw: button_html,
      parsed: button,
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
end
