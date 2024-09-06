defmodule PhoenixTest.ActiveForm do
  @moduledoc false

  defstruct [:id, :selector, :form_data, :uploads]

  def new(opts \\ []) do
    struct!(%__MODULE__{id: nil, selector: nil, form_data: [], uploads: []}, opts)
  end

  def prepend_form_data(%__MODULE__{} = active_form, default_form_data) do
    Map.update!(active_form, :form_data, &(default_form_data ++ &1))
  end

  def add_form_data(%__MODULE__{} = active_form, new_form_data) do
    Map.update!(active_form, :form_data, &(&1 ++ new_form_data))
  end

  def add_upload(%__MODULE__{} = active_form, new_upload) do
    Map.update!(active_form, :uploads, &(&1 ++ [new_upload]))
  end

  def active?(%__MODULE__{} = active_form) do
    not Enum.empty?(active_form.form_data) or not Enum.empty?(active_form.uploads)
  end
end
