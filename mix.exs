defmodule Sender.MixProject do
  use Mix.Project

  def project do
    [
      app: :sender,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :util_mq, :poison],
      mod: {Sender, []}
    ]
  end

  defp deps do
    [
      {:util_mq, git: "git@git.it.tender.pro:bot/util_mq.git"},
      {:poison, "~> 3.1"},
      {:gen_stage, "~> 0.12"}
    ]
  end
end
