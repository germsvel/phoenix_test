defmodule PhoenixTest.Element.Link do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[raw parsed id selector text href]a

  def find!(html, selector, text) do
    link = Query.find!(html, selector, text)
    link_html = Html.raw(link)
    id = Html.attribute(link, "id")
    href = Html.attribute(link, "href")

    %__MODULE__{
      raw: link_html,
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
