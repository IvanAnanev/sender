defmodule Sender.Core.Sms.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_module: Sender.Queue.Sms
end
