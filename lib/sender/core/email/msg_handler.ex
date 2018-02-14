defmodule Sender.Core.Email.MsgHandler do
  @moduledoc """
    Оправка email cooбщения.
    Магия GenStage запускает этот таск в ConsumerSupervisor
  """
  import Bamboo.Email
  alias Sender.Core.Email.Mailer
  require Logger

  # 5 повторов
  @repeat_count 5
  # 10 секунд
  @repeat_time 1_000

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> prepare_email()
      |> send_email(0)
      |> log_and_send_to_mq(msg)
    end)
  end

  # формируем письмо
  defp prepare_email(msg) do
    new_email(
      to: msg["recipient"],
      from: from(),
      subject: msg["msg"]["subject"],
      text_body: msg["msg"]["text"]
    )
  end

  # отправитель
  defp from() do
    Application.get_env(:sender, Sender.Core.Email.Mailer)[:username]
  end

  # отправляем письмо
  defp send_email(_email, try_count) when try_count == @repeat_count, do: :error

  defp send_email(email, try_count) do
    try do
      Mailer.deliver_now(email)
      :ok
    rescue
      e ->
        # что то пошло не так
        Logger.error("Error to try #{try_count} send email: #{inspect(e)}")
        # повторяем отправку через @repeat_time
        :timer.sleep(@repeat_time)
        send_email(email, try_count + 1)
    end
  end

  # делаем лог и отправляем в mq статус
  defp log_and_send_to_mq(:ok, msg) do
    Logger.info("The msg #{inspect(msg)} was sent")
    Sender.MQ.Output.msg_sent(msg["id"])
  end

  defp log_and_send_to_mq(:error, msg) do
    Logger.error("The msg #{inspect(msg)} wasn't sent")
    Sender.MQ.Output.msg_error(msg["id"])
  end
end
