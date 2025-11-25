defmodule PhoenixTest.Element.Link do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[parsed id selector text href]a

  def find(html, selector, text) do
    with {:found, link} <- Query.find(html, selector, text) do
      {:found, build(link, selector, text)}
    end
  end

  def find!(html, selector, text) do
    html |> Query.find!(selector, text) |> build(selector, text)
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
