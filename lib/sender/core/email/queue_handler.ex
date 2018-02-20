defmodule Sender.Core.Email.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_module: Sender.Queue.Email.Controller
end
