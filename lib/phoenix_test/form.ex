defmodule PhoenixTest.Form do
  @moduledoc false

  alias PhoenixTest.Button
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  def find!(html, button) do
    form = Query.find_ancestor!(html, "form", {button.selector, button.text})
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
      form_data: form_data(form, button)
    }
  end

  defp form_data(form, button) do
    %{}
    |> put_form_data("input[type='hidden']", form)
    |> put_form_data("input[type='radio'][checked='checked']", form)
    |> put_button_data(button)
  end

  defp put_form_data(form_data, selector, form) do
    hidden_fields =
      form
      |> Html.all(selector)
      |> Enum.map(&to_form_field/1)
      |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)

    Map.merge(form_data, hidden_fields)
  end

  defp put_button_data(form_data, %Button{} = button) do
    if button.name && button.value do
      button_name_and_value = Utils.name_to_map(button.name, button.value)
      Map.merge(form_data, button_name_and_value)
    else
      form_data
    end
  end

  defp to_form_field(element) do
    name = Html.attribute(element, "name")
    value = Html.attribute(element, "value")
    Utils.name_to_map(name, value)
  end
end
