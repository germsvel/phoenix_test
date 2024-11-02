import Config

config :phoenix_test,
  endpoint: PhoenixTest.Endpoint,
  ecto_repos: [PhoenixTest.Repo],
  otp_app: :phoenix_test,
  playwright_cli: "priv/static/assets/node_modules/playwright/cli.js"

config :logger, level: :warning

config :phoenix_test, PhoenixTest.Endpoint,
  server: true,
  http: [port: 4000],
  live_view: [signing_salt: "112345678212345678312345678412"],
  secret_key_base: String.duplicate("57689", 50),
  pubsub_server: PhoenixTest.PubSub

config :logger, level: :error

config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../../priv/static/assets),
    cd: Path.expand("../test/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :phoenix_test, PhoenixTest.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_test_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
