defmodule Sender.Core.Email.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_controller: Sender.Queue.Email.Controller
end
