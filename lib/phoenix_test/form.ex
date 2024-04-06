defmodule PhoenixTest.Form do
  @moduledoc false

  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def find!(html, child) do
    form = Query.find_ancestor!(html, "form", {child.selector, child.text})
    raw = Html.raw(form)
    id = Html.attribute(form, "id")

    data = Html.Form.build(form)

    action = data["attributes"]["action"]
    method = data["operative_method"]

    %{
      raw: raw,
      parsed: form,
      id: id,
      action: action,
      method: method,
      form_data: %{}
    }
  end
end
