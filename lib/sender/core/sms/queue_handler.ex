defmodule Sender.Core.Sms.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_controller: Sender.Queue.Sms.Controller
end
