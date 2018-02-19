use Mix.Config

config :logger, :console,
  metadata: [:module],
  format: "\n$time [$metadata][$level] $levelpad$message\n"

import_config "#{Mix.env}.exs"
