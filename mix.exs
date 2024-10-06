defmodule PhoenixTest.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/germsvel/phoenix_test"
  @description """
  Write pipeable, fast, and easy-to-read feature tests for your Phoenix apps in
  a unified way -- regardless of whether you're testing LiveView pages or static
  pages.
  """

  def project do
    [
      app: :phoenix_test,
      version: @version,
      description: @description,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "PhoenixTest",
      source_url: @source_url,
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: [
        setup: :test,
        "assets.setup": :test,
        "assets.build": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:esbuild, "~> 0.8", runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:floki, ">= 0.30.0"},
      {:jason, "~> 1.4"},
      {:makeup_eex, "~> 0.1.0", only: :dev, runtime: false},
      {:makeup_html, "~> 0.1.0", only: :dev, runtime: false},
      {:mime, ">= 1.0.0", optional: true},
      {:phoenix, "~> 1.7.10"},
      {:phoenix_live_view, "~> 0.20.1"},
      {:plug_cowboy, "~> 2.7", only: :test, runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      {:cowlib, "~> 2.13.0", override: true},
      {:playwright, github: "ftes/playwright-elixir", ref: "phoenix-test", optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => @source_url}
    ]
  end

  defp docs do
    [
      main: "PhoenixTest",
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "upgrade_guides.md": [title: "Upgrade Guides"]
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"]
    ]
  end
end
