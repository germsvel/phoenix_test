defmodule PhoenixTest.Element.Link do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[parsed id selector text href]a

  def find(html, selector, text) do
    case Query.find(html, selector, text) do
      {:found, link} ->
        {:found, build(link, selector, text)}

      {:not_found, _potential_matches} = not_found ->
        case Query.find_by_label(html, selector, text, exact: false) do
          {:found, link} -> {:found, build(link, Element.build_selector(link), Html.element_text(link))}
          _ -> not_found
        end

      other ->
        other
    end
  end

  def find!(html, selector, text) do
    case find(html, selector, text) do
      {:found, link} -> link
      _ -> html |> Query.find!(selector, text) |> build(selector, text)
    end
  end

  defp build(link, selector, text) do
    id = Html.attribute(link, "id")
    href = Html.attribute(link, "href")

    %__MODULE__{
      parsed: link,
      id: id,
      selector: selector,
      text: text,
      href: href
    }
  end

  def has_data_method?(link) do
    link.parsed
    |> Html.attribute("data-method")
    |> Utils.present?()
  end
end
