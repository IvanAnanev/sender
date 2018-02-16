defmodule Sender.Core.Telegram.QueueHandler do
  use Sender.Core.Base.QueueHandler,
    shedule_time: 1_000,
    queue_module: Sender.Queue.Telegram
end
