defmodule PhoenixTest.Element.Form do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Button
  alias PhoenixTest.FormData
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defstruct ~w[selector parsed id action method form_data submit_button]a

  def find!(html, selector) do
    html
    |> Query.find!(selector)
    |> build()
  end

  def find(html, selector) do
    html
    |> Query.find(selector)
    |> case do
      {:found, element} -> {:found, build(element)}
      {:found_many, elements} -> {:found_many, Enum.map(elements, &build/1)}
      :not_found -> :not_found
    end
  end

  def find_by_descendant!(html, descendant) do
    html
    |> Query.find_ancestor!("form", descendant)
    |> build()
  end

  defp build(%LazyHTML{} = form) do
    id = Html.attribute(form, "id")
    action = Html.attribute(form, "action")
    selector = Element.build_selector(form)

    %__MODULE__{
      action: action,
      form_data: form_data(form),
      id: id,
      method: operative_method(form),
      parsed: form,
      selector: selector,
      submit_button: Button.find_first_submit(form)
    }
  end

  def form_element_names(%__MODULE__{} = form) do
    form.parsed
    |> Html.all("[name]")
    |> Enum.map(&Html.attribute(&1, "name"))
    |> Enum.uniq()
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

  @enabled_controls "input:not([disabled])[name], textarea:not([disabled])[name], select:not([disabled])[name]"

  defp form_data(form) do
    form
    |> Html.all(@enabled_controls)
    |> Enum.reduce(FormData.new(), &append_form_field(&2, Html.tag(&1), &1))
  end

  def put_button_data(form, nil), do: form

  def put_button_data(form, %Button{} = button) do
    Map.update!(form, :form_data, &FormData.add_data(&1, button))
  end

  defp append_form_field(form_data, "input", element) do
    name = Html.attribute(element, "name")
    value = Html.attribute(element, "value")
    type = Html.attribute(element, "type")

    cond do
      !value ->
        form_data

      type == "hidden" ->
        FormData.add_data(form_data, name, value)

      type in ~w(radio checkbox) and Html.attribute(element, "checked") ->
        FormData.add_data(form_data, name, value)

      type in ~w(radio checkbox) ->
        form_data

      true ->
        FormData.add_data(form_data, name, value)
    end
  end

  defp append_form_field(form_data, "textarea", element) do
    FormData.add_data(form_data, to_form_field(element))
  end

  defp append_form_field(form_data, "select", select) do
    values =
      select
      |> Html.selected_options()
      |> Enum.map(&element_value/1)

    case values do
      [] -> form_data
      [value] -> FormData.add_data(form_data, Html.attribute(select, "name"), value)
      many -> FormData.add_data(form_data, Html.attribute(select, "name"), many)
    end
  end

  defp to_form_field(element) do
    to_form_field(element, element)
  end

  defp to_form_field(name_element, value_element) do
    name = Html.attribute(name_element, "name")
    {name, element_value(value_element)}
  end

  defp element_value(element) do
    Html.attribute(element, "value") || Html.element_text(element)
  end

  defp operative_method(%LazyHTML{} = form) do
    hidden_input_method_value(form) || Html.attribute(form, "method") || "get"
  end

  defp hidden_input_method_value(form) do
    form
    |> Html.all("input[type='hidden'][name='_method']")
    |> Enum.find_value(&Html.attribute(&1, "value"))
  end
end
