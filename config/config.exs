use Mix.Config

config :logger, :console,
  metadata: [:module],
  format: "\n$time [$metadata][$level] $levelpad$message\n"

config :sender,
  queue_dump_folder: :queue_dumps,
  mq_input: "message.new",
  mq_output: "tender.sender.out"

# UtilMQ
config :util_mq, :options,
  mq_type: :mqnats,
  autoconnect: true,
  host: "0.0.0.0",
  port: 4222,
  timeout: 6000
