defmodule Sender.Core.Telegram.MsgHandlerSupervisor do
  use Sender.Core.Base.MsgHandlerSupervisor,
    queue_handler: Sender.Core.Telegram.QueueHandler,
    msg_handler: Sender.Core.Telegram.MsgHandler,
    max_demand: 10
end
