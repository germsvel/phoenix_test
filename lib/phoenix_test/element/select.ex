defmodule PhoenixTest.Element.Select do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query

  @enforce_keys ~w[source_raw selected_options parsed label id name value selector]a
  defstruct ~w[source_raw selected_options parsed label id name value selector]a

  def find_select_option!(html, input_selector, label, option, opts) do
    field = Query.find_by_label!(html, input_selector, label, opts)
    id = Html.attribute(field, "id")
    name = Html.attribute(field, "name")

    multiple = not is_nil(Html.attribute(field, "multiple"))

    exact_option = Keyword.get(opts, :exact_option, true)

    selected_options =
      case {multiple, option} do
        {true, [_ | _]} ->
          Enum.map(option, fn opt ->
            Query.find!(Html.raw(field), "option", opt, exact: exact_option)
          end)

        {true, _} ->
          [Query.find!(Html.raw(field), "option", option, exact: exact_option)]

        {false, [_ | _]} ->
          msg = """
          Could not find a select with a "multiple" attribute set.

          Found the following select:

          #{Html.raw(field)}
          """

          raise ArgumentError, msg

        {false, _} ->
          [field |> Html.raw() |> Query.find!("option", option, exact: exact_option)]
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
    Enum.all?(field.selected_options, &LiveViewBindings.phx_click?/1)
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
