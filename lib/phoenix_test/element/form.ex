defmodule PhoenixTest.Element.Form do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Button
  alias PhoenixTest.FormData
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
    action = Html.attribute(form, "action")
    selector = Element.build_selector(form)

    %__MODULE__{
      action: action,
      form_data: form_data(form),
      id: id,
      method: operative_method(form),
      parsed: form,
      raw: raw,
      selector: selector,
      submit_button: Button.find_first(raw)
    }
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

  defp descendant_selector(%{id: id}) when is_binary(id), do: "[id=#{inspect(id)}]"
  defp descendant_selector(%{selector: selector, text: text}), do: {selector, text}
  defp descendant_selector(%{selector: selector}), do: selector

  @hidden_inputs "input[type=hidden]"
  @checked_radio_buttons "input:not([disabled])[type=radio][checked=checked][value]"
  @checked_checkboxes "input:not([disabled])[type=checkbox][checked=checked][value]"
  @pre_filled_text_inputs "input:not([disabled])[type=text][value]"
  @pre_filled_number_inputs "input:not([disabled])[type=number][value]"
  @pre_filled_default_text_inputs "input:not([disabled]):not([type])[value]"

  defp form_data(form) do
    FormData.new()
    |> FormData.add_data(form_data(@hidden_inputs, form))
    |> FormData.add_data(form_data(@checked_radio_buttons, form))
    |> FormData.add_data(form_data(@checked_checkboxes, form))
    |> FormData.add_data(form_data(@pre_filled_text_inputs, form))
    |> FormData.add_data(form_data(@pre_filled_number_inputs, form))
    |> FormData.add_data(form_data(@pre_filled_default_text_inputs, form))
    |> FormData.add_data(form_data_textarea(form))
    |> FormData.add_data(form_data_select(form))
  end

  defp form_data(selector, form) do
    form
    |> Html.all(selector)
    |> Enum.flat_map(&to_form_field/1)
  end

  defp form_data_textarea(form) do
    form
    |> Html.all("textarea:not([disabled])")
    |> Enum.flat_map(fn {"textarea", _attrs, value_elements} = textarea ->
      to_form_field(textarea, value_elements)
    end)
  end

  defp form_data_select(form) do
    form
    |> Html.all("select")
    |> Enum.flat_map(fn select ->
      multiple = !is_nil(Html.attribute(select, "multiple"))

      case {Html.all(select, "option"), multiple, Html.all(select, "option[selected]")} do
        {[], _, _} -> []
        {_, false, [only_selected]} -> to_form_field(select, only_selected)
        {_, true, [_ | _] = all_selected} -> to_form_field(select, all_selected)
        {[first | _], false, _} -> to_form_field(select, first)
        {_, true, _} -> to_form_field(select, [])
      end
    end)
  end

  def put_button_data(form, nil), do: form

  def put_button_data(form, %Button{} = button) do
    button_data = FormData.to_form_data(button)
    Map.update!(form, :form_data, &FormData.add_data(&1, button_data))
  end

  defp to_form_field(element) do
    to_form_field(element, element)
  end

  defp to_form_field(name_element, value_elements) when is_list(value_elements) do
    name = Html.attribute(name_element, "name")
    values = Enum.map(value_elements, &element_value/1)
    FormData.to_form_data(name, values)
  end

  defp to_form_field(name_element, value_element) do
    name = Html.attribute(name_element, "name")
    FormData.to_form_data(name, element_value(value_element))
  end

  defp element_value(element) do
    Html.attribute(element, "value") || Html.text(element)
  end

  defp operative_method({"form", _attrs, fields} = form) do
    hidden_input_method_value(fields) || Html.attribute(form, "method") || "get"
  end

  defp hidden_input_method_value(fields) do
    fields
    |> Enum.find(:no_method_input, fn
      {"input", _, _} = field ->
        Html.attribute(field, "name") == "_method"

      _ ->
        false
    end)
    |> case do
      :no_method_input -> nil
      field -> Html.attribute(field, "value")
    end
  end
end
