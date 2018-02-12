defmodule Sender do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Sender.Worker.start_link(arg)
      # {Sender.Worker, arg},
      {Sender.Queue.Email, []},
      {Sender.Queue.Sms, []},
      {Sender.Queue.Telegram, []},
      {Sender.Queue.Wechat, []},
      {Sender.Queue.Pusher, []},
      {Sender.MQ.Input, []},
      {Sender.MQ.Output, []},
      {Sender.Core.Email.QueueHandler, []},
      {Sender.Core.Email.MsgHandlerSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sender.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
