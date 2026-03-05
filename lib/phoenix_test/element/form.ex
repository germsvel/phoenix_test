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

  @simple_value_types ~w(
    date
    datetime-local
    email
    month
    number
    password
    range
    search
    tel
    text
    time
    url
    week
  )

  @hidden_inputs "input[type='hidden']"
  @checked_radio_buttons "input:not([disabled])[type='radio'][value]:checked"
  @checked_checkboxes "input:not([disabled])[type='checkbox'][value]:checked"
  @pre_filled_default_text_inputs "input:not([disabled]):not([type])[value]"

  @pre_filled_simple_value_inputs Enum.map_join(
                                    @simple_value_types,
                                    ",",
                                    &"input:not([disabled])[type='#{&1}'][value]"
                                  )

  defp form_data(form) do
    FormData.new()
    |> FormData.add_data(form_data(@hidden_inputs, form))
    |> FormData.add_data(form_data(@checked_radio_buttons, form))
    |> FormData.add_data(form_data(@checked_checkboxes, form))
    |> FormData.add_data(form_data(@pre_filled_simple_value_inputs, form))
    |> FormData.add_data(form_data(@pre_filled_default_text_inputs, form))
    |> FormData.add_data(form_data_textarea(form))
    |> FormData.add_data(form_data_select(form))
  end

  defp form_data(selector, form) do
    form
    |> Html.all(selector)
    |> Enum.map(&to_form_field/1)
  end

  defp form_data_textarea(form) do
    form
    |> Html.all("textarea:not([disabled])")
    |> Enum.map(&to_form_field/1)
  end

  defp form_data_select(form) do
    form
    |> Html.all("select:not([disabled])")
    |> Enum.flat_map(fn select ->
      selected_options = Html.all(select, "option[selected]")
      multiple? = Html.attribute(select, "multiple") != nil

      case {multiple?, Enum.count(selected_options)} do
        {true, 0} ->
          []

        {false, 0} ->
          if option = select |> Html.all("option") |> Enum.at(0) do
            [to_form_field(select, option)]
          else
            []
          end

        {false, _} ->
          [to_form_field(select, selected_options)]

        _ ->
          Enum.map(selected_options, &to_form_field(select, &1))
      end
    end)
  end

  def put_button_data(form, nil), do: form

  def put_button_data(form, %Button{} = button) do
    Map.update!(form, :form_data, &FormData.add_data(&1, button))
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
