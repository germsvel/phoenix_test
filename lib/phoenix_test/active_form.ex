defmodule PhoenixTest.ActiveForm do
  @moduledoc false

  alias PhoenixTest.FormData

  defstruct [:id, :selector, form_data: FormData.new(), uploads: FormData.new()]

  @doc """
  Data structure for tracking active form fields filled.

  Do not keep track of default form data on the page. That's what
  `PhoenixTest.Form.form_data` is for.
  """
  def new(opts \\ []) when is_list(opts) do
    struct!(%__MODULE__{}, opts)
  end

  def put_form_data(%__MODULE__{} = active_form, name, value) do
    Map.update!(active_form, :form_data, &FormData.put_data(&1, name, value))
  end

  def add_upload(%__MODULE__{} = active_form, new_upload) do
    Map.update!(active_form, :uploads, &FormData.add_data(&1, new_upload))
  end

  def active?(%__MODULE__{} = active_form) do
    not FormData.empty?(active_form.form_data) or not FormData.empty?(active_form.uploads)
  end
end
