defmodule Sender.Queue.Wechat.Controller do
  use Sender.Queue.Controller,
    change_time: 10_000,
    first_queue: Sender.Queue.Wechat.First,
    second_queue: Sender.Queue.Wechat.Second
end
