defmodule Sender.Core.Email.MsgHandler do
  @moduledoc """
  Непосредственная логика отправки сообщения должна быть здесь
  """
  require Logger


  def start_link(msg) do
    Task.start_link(fn ->
      Logger.info("this is work! #{msg["id"]}")
      Sender.MQ.Output.msg_sent(msg["id"])
    end)
  end
end