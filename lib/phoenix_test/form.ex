defmodule PhoenixTest.Form do
  @moduledoc false

  alias PhoenixTest.Button
  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[selector raw parsed id action method form_data submit_button]a

  def find!(html, selector) do
    html
    |> Query.find!(selector)
    |> build()
  end

  def find_by_descendant!(html, descendant) do
    html
    |> Query.find_ancestor!("form", descendant_selector(descendant))
    |> build()
  end

  defp build(form) do
    raw = Html.raw(form)
    id = Html.attribute(form, "id")
    selector = Element.build_selector(form)

    data = Html.Form.build(form)

    action = data["attributes"]["action"]
    method = data["operative_method"]

    %__MODULE__{
      selector: selector,
      raw: raw,
      parsed: form,
      id: id,
      action: action,
      method: method,
      form_data: form_data(form),
      submit_button: Button.find_first(raw)
    }
  end

  defp descendant_selector(descendant) do
    if descendant.id do
      "##{descendant.id}"
    else
      {descendant.selector, descendant.text}
    end
  end

  def phx_change?(form) do
    form.parsed
    |> Html.attribute("phx-change")
    |> Utils.present?()
  end

  def phx_submit?(form) do
    form.parsed
    |> Html.attribute("phx-submit")
    |> Utils.present?()
  end

  def has_action?(form), do: Utils.present?(form.action)

  defp form_data(form) do
    %{}
    |> put_form_data("input[type=hidden]", form)
    |> put_form_data("input[type=radio][checked=checked][value]", form)
    |> put_form_data("input[type=checkbox][checked=checked][value]", form)
    |> put_form_data(
      "input:not([disabled]):not([type=radio]):not([type=checkbox]):not([type=button]):not([type=submit])[value]",
      form
    )
    |> put_form_data_select(form)
  end

  defp put_form_data(form_data, selector, form) do
    input_fields =
      form
      |> Html.all(selector)
      |> Enum.map(&to_form_field/1)
      |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)

    Map.merge(form_data, input_fields)
  end

  defp put_form_data_select(form_data, form) do
    selects =
      form
      |> Html.all("select")
      |> Enum.reduce(%{}, fn select, acc ->
        case {Html.all(select, "option"), Html.all(select, "option[selected]")} do
          {[], _} -> acc
          {_, [only_selected]} -> Map.merge(acc, to_form_field(select, only_selected))
          {[first | _], _} -> Map.merge(acc, to_form_field(select, first))
        end
      end)

    Map.merge(form_data, selects)
  end

  def put_button_data(form, nil), do: form

  def put_button_data(form, %Button{} = button) do
    if button.name && button.value do
      button_name_and_value = Utils.name_to_map(button.name, button.value)
      update_in(form.form_data, fn data -> Map.merge(button_name_and_value, data) end)
    else
      form
    end
  end

  defp to_form_field(element) do
    to_form_field(element, element)
  end

  defp to_form_field(name_element, value_element) do
    name = Html.attribute(name_element, "name")
    value = Html.attribute(value_element, "value")
    Utils.name_to_map(name, value)
  end
end
