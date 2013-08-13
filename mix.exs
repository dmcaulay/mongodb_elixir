defmodule MongoDB.Mixfile do
  use Mix.Project

  def project do
    [ app: :mongodb_elixir,
      version: "0.0.1",
      elixir: "~> 0.10.2-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:bson, :mongodb] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      { :'mongodb', "v0.3.2", git: "https://github.com/dmcaulay/mongodb-erlang.git", branch: "refactor", tag: "v0.3.2" }
    ]
  end
end
