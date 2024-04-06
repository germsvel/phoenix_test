defmodule PhoenixTest.Element do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def find!(html, selector, text) do
    element = Query.find!(html, selector, text)
    element_html = Html.raw(element)
    id = Html.attribute(element, "id")

    %{
      raw: element_html,
      parsed: element,
      id: id,
      selector: selector,
      text: text
    }
  end

  def find_parent_form!(html, selector, text) do
    form = Query.find_ancestor!(html, "form", {selector, text})
    raw = Html.raw(form)
    id = Html.attribute(form, "id")

    %{
      raw: raw,
      parsed: form,
      id: id
    }
  end
end
