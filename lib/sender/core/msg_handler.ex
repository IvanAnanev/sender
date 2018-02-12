defmodule Sender.Core.MsgHandler do
  require Logger

  def start_link(msg) do
    Task.start_link(fn ->
      Logger.info("this is work! #{msg["id"]}")
      Sender.MQ.Output.msg_sent(msg["id"])
    end)
  end
end
