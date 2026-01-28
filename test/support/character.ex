defmodule PhoenixTest.Character do
  @moduledoc false
  defstruct [:name]

  defimpl Phoenix.HTML.Safe do
    alias PhoenixTest.Character

    def to_iodata(%Character{} = character) do
      character.name
    end
  end
end
