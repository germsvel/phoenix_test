import Config

config :playwright, LaunchOptions, headless: String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false
