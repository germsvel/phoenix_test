defmodule PhoenixTest.Button do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def find!(html, selector, text) do
    button = Query.find!(html, selector, text)
    button_html = Html.raw(button)
    id = Html.attribute(button, "id")

    %{
      raw: button_html,
      parsed: button,
      id: id,
      selector: selector,
      text: text
    }
  end
end
