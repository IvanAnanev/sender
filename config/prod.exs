use Mix.Config

config :sender,
  queue_dump_folder: :queue_dumps,
  mq_input:  {:system, :string, "MQ_INPUT", nil},
  mq_output:  {:system, :string, "MQ_OUTPUT", nil}

# UtilMQ
config :util_mq, :options,
  mq_type: :mqnats,
  autoconnect: true,
  host: {:system, :string, "NATS_HOST", nil},
  port: 4222,
  timeout: 6000

config :sender, Sender.Core.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.yandex.ru",
  port: 465,
  username: {:system, :string, "EMAIL_USER_NAME", nil},
  password: {:system, :string, "EMAIL_PASSWORD", nil},
  tls: :if_available,
  allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"],
  ssl: true

config :sender, :sms,
  api_url: "https://sms.ru/sms",
  api_key: {:system, :string, "SMSRU_API_KEY", nil}
  # from: {:system, :string, "SMSRU_FROM", nil}

config :sender, :telegram,
  api_url: "https://api.telegram.org",
  token: {:system, :string, "TELEGRAM_TOKEN", nil}

config :sender, :wechat,
  api_url: "https://api.wechat.com/cgi-bin",
  app_id: {:system, :string, "WECHAT_APP_ID", nil},
  app_secret: {:system, :string, "WECHAT_APP_SECRET", nil}
