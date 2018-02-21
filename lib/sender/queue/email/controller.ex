defmodule Sender.Queue.Email.Controller do
  use Sender.Queue.Controller,
    change_time: 10_000,
    first_queue: Sender.Queue.Email.First,
    second_queue: Sender.Queue.Email.Second
end
