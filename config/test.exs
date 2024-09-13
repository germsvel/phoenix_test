import Config

config :phoenix_test, :endpoint, PhoenixTest.Endpoint

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
