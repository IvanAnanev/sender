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
      extra_applications: [
        :confex, :logger, :util_mq, :poison, :bamboo,
        :bamboo_smtp, :httpoison, :nats, :plug
      ],
      mod: {Sender, []}
    ]
  end

  defp deps do
    [
      {:util_mq, git: "git@git.it.tender.pro:bot/util_mq.git"},
      {:poison, "~> 3.1"},
      {:gen_stage, "~> 0.12"},
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:httpoison, "~> 1.0"},
      {:confex, "~> 3.3.1"},
      {:distillery, "~> 1.5", runtime: false}
    ]
  end
end
