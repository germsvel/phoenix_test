defmodule PhoenixTest.ActiveForm do
  @moduledoc false

  defstruct [:id, :selector, form_data: [], uploads: []]

  @doc """
  Data structure for tracking active form fields filled.

  Do not keep track of default form data on the page. That's what
  `PhoenixTest.Form.form_data` is for.
  """
  def new(opts \\ []) when is_list(opts) do
    struct!(%__MODULE__{}, opts)
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
