defmodule Sender do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Sender.Queue.Email, []},
      {Sender.Queue.Sms, []},
      {Sender.Queue.Telegram, []},
      {Sender.Queue.Wechat, []},
      {Sender.Queue.Pusher, []},
      {Sender.MQ.Input, []},
      {Sender.MQ.Output, []},
      {Sender.Core.Email.QueueHandler, []},
      {Sender.Core.Email.MsgHandlerSupervisor, []},
      {Sender.Core.Sms.QueueHandler, []},
      {Sender.Core.Sms.MsgHandlerSupervisor, []},
      {Sender.Core.Telegram.QueueHandler, []},
      {Sender.Core.Telegram.MsgHandlerSupervisor, []},
      {Sender.Core.Wechat.AccessToken, []},
      {Sender.Core.Wechat.QueueHandler, []},
      {Sender.Core.Wechat.MsgHandlerSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Sender.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
