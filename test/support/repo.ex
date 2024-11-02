defmodule PhoenixTest.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_test,
    adapter: Ecto.Adapters.Postgres
end
