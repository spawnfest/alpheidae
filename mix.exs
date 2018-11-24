defmodule Alpheidae.MixProject do
  use Mix.Project

  def project do
    [
      app: :alpheidae,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:exprotobuf, "~> 1.2"},
      {:ranch, "~> 1.4.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp aliases do
    [
      dev_setup: ["cmd mkdir _keys", "cmd openssl req -x509 -newkey rsa:4096 -keyout _keys/key.pem -out _keys/cert.pem -days 365 -nodes -subj '/CN=localhost'"]
    ]
  end
end
