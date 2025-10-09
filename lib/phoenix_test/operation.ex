defmodule PhoenixTest.Operation do
  @moduledoc false
  defstruct [:name, :html]

  def new(name, html) do
    %__MODULE__{name: name, html: html}
  end
end
