defmodule PhoenixTest.WebApp.VerificationProfile do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:name, :string, default: "Original")
    field(:subscribed, :boolean, default: false)
  end

  def changeset(profile), do: cast(profile, %{}, [:name, :subscribed])
end
