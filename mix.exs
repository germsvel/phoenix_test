defmodule PhoenixTest.MixProject do
  use Mix.Project

  @version "0.2.6"
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
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "PhoenixTest",
      source_url: @source_url,
      docs: docs()
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:floki, ">= 0.30.0"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7.10"},
      {:phoenix_live_view, "~> 0.20.1"}
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
      main: "readme",
      extras: ["README.md": [title: "Introduction"], "CHANGELOG.md": [title: "Changelog"]]
    ]
  end
end
