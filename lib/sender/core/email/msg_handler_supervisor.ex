defmodule Sender.Core.Email.MsgHandlerSupervisor do
  use Sender.Core.Base.MsgHandlerSupervisor,
    queue_handler: Sender.Core.Email.QueueHandler,
    msg_handler: Sender.Core.Email.MsgHandler,
    max_demand: 10
end
