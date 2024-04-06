defmodule PhoenixTest.Button do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

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
end
