defmodule PhoenixTest.Element.Select do
  @moduledoc false

  alias PhoenixTest.Element
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings
  alias PhoenixTest.Query

  @enforce_keys ~w[selected_options parsed label id name value selector]a
  defstruct ~w[selected_options parsed label id name value selector]a

  def find_select_option(html, input_selector, label, option, opts) do
    with {:ok, field} <- Query.find_by_label(html, input_selector, label, opts),
         {:ok, selected_options} <- find_options(field, option, opts) do
      {:ok,
       %__MODULE__{
         parsed: field,
         label: label,
         id: Html.attribute(field, "id"),
         name: Html.attribute(field, "name"),
         value: Enum.map(selected_options, &Html.attribute(&1, "value")),
         selected_options: selected_options,
         selector: Element.build_selector(field)
       }}
    end
  end

  def phx_click_options?(field), do: Enum.all?(field.selected_options, &LiveViewBindings.phx_click?/1)
  def select_option_selector(field, value), do: field.selector <> " option[value=#{inspect(value)}]"
  def belongs_to_form?(field, html), do: Query.has_ancestor?(html, "form", field)

  defp find_options(field, option, opts) do
    multiple = not is_nil(Html.attribute(field, "multiple"))
    exact_option = Keyword.get(opts, :exact_option, true)

    case {multiple, option} do
      {true, options} when is_list(options) -> traverse_options(field, options, exact_option)
      {true, option} -> traverse_options(field, [option], exact_option)
      {false, options} when is_list(options) -> raise_multiple_option_error(field)
      {false, option} -> traverse_options(field, [option], exact_option)
    end
  end

  defp traverse_options(field, options, exact_option) do
    options
    |> Enum.reduce_while({:ok, []}, fn option, {:ok, found} ->
      case Query.find(field, "option", option, exact: exact_option) do
        {:ok, selected_option} -> {:cont, {:ok, [selected_option | found]}}
        {:error, failure} -> {:halt, {:error, failure}}
      end
    end)
    |> then(fn
      {:ok, found} -> {:ok, Enum.reverse(found)}
      error -> error
    end)
  end

  defp raise_multiple_option_error(field) do
    raise ArgumentError, """
    Could not find a select with a "multiple" attribute set.

    Found the following select:

    #{Html.raw(field)}
    """
  end
end
