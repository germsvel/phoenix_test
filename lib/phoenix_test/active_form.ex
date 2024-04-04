defmodule PhoenixTest.ActiveForm do
  @moduledoc false

  def new, do: %{form_data: %{}}

  def prepend_form_data(active_form, default_form_data) do
    active_form
    |> Map.update(:form_data, %{}, fn form_data ->
      DeepMerge.deep_merge(default_form_data, form_data)
    end)
  end

  def add_form_data(active_form, new_form_data) do
    active_form
    |> Map.update(:form_data, %{}, fn form_data ->
      DeepMerge.deep_merge(form_data, new_form_data)
    end)
  end

  def active?(%{selector: _}), do: true
  def active?(%{}), do: false
end
