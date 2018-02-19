use Mix.Config

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

config :sender, Sender.Core.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.yandex.ru",
  port: 465,
  username: "YOUR_EMAIL@yandex.ru",
  password: "YOUR_EMAIL_PASSWORD",
  tls: :if_available,
  allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"],
  ssl: true

config :sender, :sms,
  api_url: "https://sms.ru/sms",
  api_key: "YOUR_API_KEY"
  from: "UZAF"

config :sender, :telegram,
  api_url: "https://api.telegram.org",
  token: "YOUR_TOKEN"

config :sender, :wechat,
  api_url: "https://api.wechat.com/cgi-bin",
  app_id: "YOUR_API_ID",
  app_secret: "YOUR_SECRET"
