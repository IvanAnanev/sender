use Mix.Config

config :sender,
  queue_dump_folder: :queue_dumps,
  mq_input:  {:system, :string, "MQ_INPUT", "tender.sender.in"},
  mq_output:  {:system, :string, "MQ_OUTPUT", "tender.sender.out"}

# UtilMQ
config :util_mq, :options,
  mq_type: :mqnats,
  autoconnect: true,
  host: {:system, :string, "NATS_HOST", "0.0.0.0"},
  port: 4222,
  timeout: 6000

config :sender, Sender.Core.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.yandex.ru",
  port: 465,
  username: {:system, :string, "EMAIL_USER_NAME", "YOUR_EMAIL_USER_NAME"},
  password: {:system, :string, "EMAIL_PASSWORD", "YOUR_EMAIL_PASSWORD"},
  tls: :if_available,
  allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"],
  ssl: true

config :sender, :sms,
  api_url: "https://sms.ru/sms",
  api_key: {:system, :string, "SMSRU_API_KEY", "YOUR_SMSRU_API_KEY"},
  from: {:system, :string, "SMSRU_FROM", "YOUR_SMSRU_FROM"}

config :sender, :telegram,
  api_url: "https://api.telegram.org",
  token: {:system, :string, "TELEGRAM_TOKEN", "YOUR_TELEGRAM_TOKEN"}

config :sender, :wechat,
  api_url: "https://api.wechat.com/cgi-bin",
  app_id: {:system, :string, "WECHAT_APP_ID", "YOUR_WECHAT_APP_ID"},
  app_secret: {:system, :string, "WECHAT_APP_SECRET", "YOUR_WECHAT_APP_SECRET"}
