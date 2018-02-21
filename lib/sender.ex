defmodule Sender do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # email очередь
      {Sender.Queue.Email.First, []},
      {Sender.Queue.Email.Second, []},
      {Sender.Queue.Email.Controller, []},
      # sms очередь
      {Sender.Queue.Sms.First, []},
      {Sender.Queue.Sms.Second, []},
      {Sender.Queue.Sms.Controller, []},
      # telegram очередь
      {Sender.Queue.Telegram.First, []},
      {Sender.Queue.Telegram.Second, []},
      {Sender.Queue.Telegram.Controller, []},
      # {Sender.Queue.Wechat, []},
      {Sender.Queue.Pusher, []},
      # mq сервисы
      {Sender.MQ.Input, []},
      {Sender.MQ.Output, []},
      # gen_stage конвеер email
      {Sender.Core.Email.QueueHandler, []},
      {Sender.Core.Email.MsgHandlerSupervisor, []},
      # gen_stage конвеер sms
      {Sender.Core.Sms.QueueHandler, []},
      {Sender.Core.Sms.MsgHandlerSupervisor, []},
      # gen_stage конвеер telegram
      {Sender.Core.Telegram.QueueHandler, []},
      {Sender.Core.Telegram.MsgHandlerSupervisor, []},
      # {Sender.Core.Wechat.AccessToken, []},
      # {Sender.Core.Wechat.QueueHandler, []},
      # {Sender.Core.Wechat.MsgHandlerSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Sender.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
