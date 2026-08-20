defmodule PhoenixTest.Element.Link do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[parsed id selector text href]a

  def find(html, selector, text) do
    case Query.find(html, selector, text) do
      {:ok, link} ->
        {:ok, build(link, selector, text)}

      {:error, %{kind: :not_found} = failure} ->
        case Query.find_by_label(html, selector, text, exact: false) do
          {:ok, link} -> {:ok, build(link, Element.build_selector(link), Html.element_text(link))}
          {:error, _label_failure} -> {:error, failure}
        end

      {:error, _failure} = error ->
        error
    end
  end

  def find!(html, selector, text), do: html |> find(selector, text) |> Element.unwrap_query!()

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
