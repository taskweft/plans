defmodule Taskweft.Plans.MixProject do
  use Mix.Project

  @version "0.2.0-dev.0"

  def project do
    [
      app: :taskweft_plans,
      version: @version,
      elixir: "~> 1.17",
      description: "JSON-LD HTN planning domains and problems for Taskweft",
      package: package(),
      source_url: "https://github.com/taskweft/plans",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ~w(priv mix.exs LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/taskweft/plans"}
    ]
  end
end
