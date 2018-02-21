defmodule Sender.Core.Wechat.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_controller: Sender.Queue.Wechat.Controller
end
