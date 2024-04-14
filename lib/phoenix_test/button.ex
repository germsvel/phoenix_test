defmodule PhoenixTest.Button do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[raw parsed id selector text name value]a

  def find!(html, selector, text) do
    html
    |> Query.find!(selector, text)
    |> build()
  end

  def build(parsed) do
    button_html = Html.raw(parsed)
    id = Html.attribute(parsed, "id")
    name = Html.attribute(parsed, "name")
    value = Html.attribute(parsed, "value")
    selector = build_selector(id, parsed)
    text = Html.text(parsed)

    %__MODULE__{
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

  defp build_selector(id, _) when is_binary(id), do: "##{id}"

  defp build_selector(_, {"button", attributes, _}) do
    Enum.reduce(attributes, "button", fn
      {"class", _}, acc -> acc
      {k, v}, acc -> acc <> "[#{k}=#{inspect(v)}]"
    end)
  end
end
