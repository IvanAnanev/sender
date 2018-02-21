defmodule Sender.Queue.Telegram.Controller do
  use Sender.Queue.Controller,
    change_time: 10_000,
    first_queue: Sender.Queue.Telegram.First,
    second_queue: Sender.Queue.Telegram.Second
end
