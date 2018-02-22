defmodule Sender.Core.Sms.MsgHandlerSupervisor do
  use Sender.Core.Base.MsgHandlerSupervisor,
    queue_handler: Sender.Core.Sms.QueueHandler,
    msg_handler: Sender.Core.Sms.MsgHandler,
    max_demand: 1_000
end
