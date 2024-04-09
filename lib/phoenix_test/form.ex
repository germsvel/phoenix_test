defmodule PhoenixTest.Form do
  @moduledoc false

  alias PhoenixTest.Button
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[selector raw parsed id action method form_data]a

  def find!(html, selector) do
    form = Query.find!(html, selector)
    raw = Html.raw(form)
    id = Html.attribute(form, "id")

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
      form_data: form_data(form)
    }
  end

  def find_by_descendant!(html, descendant) do
    form = Query.find_ancestor!(html, "form", descendant_selector(descendant))
    raw = Html.raw(form)
    id = Html.attribute(form, "id")
    selector = build_selector(id, form)

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
      form_data: form_data(form)
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
    phx_change = Html.attribute(form.parsed, "phx-change")
    phx_change != nil and phx_change != ""
  end

  def phx_submit?(form) do
    phx_submit = Html.attribute(form.parsed, "phx-submit")
    phx_submit != nil and phx_submit != ""
  end

  def has_action?(form) do
    form.action != nil and form.action != ""
  end

  defp build_selector(id, _) when is_binary(id), do: "##{id}"

  defp build_selector(_, {"form", attributes, _}) do
    Enum.reduce(attributes, "form", fn {k, v}, acc ->
      acc <> "[#{k}=#{inspect(v)}]"
    end)
  end

  defp form_data(form) do
    %{}
    |> put_form_data("input[type='hidden']", form)
    |> put_form_data("input[type='radio'][checked='checked']", form)
  end

  defp put_form_data(form_data, selector, form) do
    hidden_fields =
      form
      |> Html.all(selector)
      |> Enum.map(&to_form_field/1)
      |> Enum.reduce(%{}, fn value, acc -> Map.merge(acc, value) end)

    Map.merge(form_data, hidden_fields)
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
    name = Html.attribute(element, "name")
    value = Html.attribute(element, "value")
    Utils.name_to_map(name, value)
  end
end
