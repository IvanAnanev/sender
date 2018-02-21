defmodule Sender.Queue.Sms.Controller do
  use Sender.Queue.Controller,
    change_time: 10_000,
    first_queue: Sender.Queue.Sms.First,
    second_queue: Sender.Queue.Sms.Second
end
