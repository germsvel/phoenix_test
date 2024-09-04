defmodule PhoenixTest.Select do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  @enforce_keys ~w[source_raw selected_options parsed label id name value selector]a
  defstruct ~w[source_raw selected_options parsed label id name value selector]a

  def find_select_option!(html, label, option) do
    field = Query.find_by_label!(html, label)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    multiple = Html.attribute(field, "multiple") == "multiple"

    selected_options =
      case {multiple, option} do
        {true, [_ | _]} ->
          Enum.map(option, fn opt ->
            Query.find!(Html.raw(field), "option", opt)
          end)

        {true, _} ->
          [Query.find!(Html.raw(field), "option", option)]

        {false, [_ | _]} ->
          msg = """
          Could not find a select with a "multiple" attribute set.

          Found the following select:

          #{Html.raw(field)}
          """

          raise ArgumentError, msg

        {false, _} ->
          [field |> Html.raw() |> Query.find!("option", option)]
      end

    values = Enum.map(selected_options, fn option -> Html.attribute(option, "value") end)

    %__MODULE__{
      source_raw: html,
      parsed: field,
      label: label,
      id: id,
      name: name,
      value: values,
      selected_options: selected_options,
      selector: Element.build_selector(field)
    }
  end

  def phx_click_options?(field) do
    Enum.all?(field.selected_options, fn option ->
      option
      |> Html.attribute("phx-click")
      |> Utils.present?()
    end)
  end

  def select_option_selector(field, value) do
    field.selector <> " option[value=#{inspect(value)}]"
  end

  def belongs_to_form?(field) do
    case Query.find_ancestor(field.source_raw, "form", field.selector) do
      {:found, _} -> true
      _ -> false
    end
  end
end
