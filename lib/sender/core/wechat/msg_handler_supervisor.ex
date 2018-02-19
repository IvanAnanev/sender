defmodule Sender.Core.Wechat.MsgHandlerSupervisor do
  use Sender.Core.Base.MsgHandlerSupervisor,
    queue_handler: Sender.Core.Wechat.QueueHandler,
    msg_handler: Sender.Core.Wechat.MsgHandler,
    max_demand: 10
end
