defmodule PhoenixTest.ActiveForm do
  @moduledoc false

  def new(opts \\ []) do
    Map.merge(%{id: nil, selector: nil, form_data: []}, Map.new(opts))
  end

  def prepend_form_data(active_form, default_form_data) do
    Map.update!(active_form, :form_data, &(default_form_data ++ &1))
  end

  def add_form_data(active_form, new_form_data) do
    Map.update!(active_form, :form_data, &(&1 ++ new_form_data))
  end

  def active?(%{form_data: form_data}) do
    !Enum.empty?(form_data)
  end
end
