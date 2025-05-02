defmodule Cerber.MixProject do
  use Mix.Project

  def project do
    [
      app: :cerber,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Cerber, []}
    ]
  end

  # Escript configuration for CLI
  defp escript do
    [
      main_module: Cerber,
      name: "crbr",
      comment: "Cerber Project Management CLI"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:dotenvy, "~> 0.8"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end
end
