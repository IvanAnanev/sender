defmodule Sender.Core.Telegram.MsgHandler do
  @moduledoc """
  Модуль отправки Telegram сообщения
  """
  require Logger

  # 5 повторов
  @repeat_count 5
  # 10 секунд
  @repeat_time 10_000

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> prepare_message()
      |> send_message(0)
      |> log_and_send_to_mq(msg)
    end)
  end

  # подготавливаем сообщение
  defp prepare_message(msg) do
    [
      chat_id: msg["recipient"],
      text: msg["msg"]["text"]
    ]
  end

  # отправка с повтором в случае ошибки
  defp send_message(_msg, try_count) when try_count == @repeat_count do
    {:error, "Can't send message after #{@repeat_count} tries"}
  end

  defp send_message(msg, try_count) do
    case make_send_msg(msg) do
      :ok ->
        :ok

      {:error, err_msg} ->
        Logger.error(err_msg)
        :timer.sleep(@repeat_time)
        send_message(msg, try_count + 1)
    end
  end

  # отправляем сообщение
  defp make_send_msg(msg) do
    url = send_msg_url()

    HTTPoison.get(url, [], params: msg)
    |> parse_answer()
  end

  # адрес АПИ для запроса
  defp send_msg_url() do
    "#{telegram_cfg()[:api_url]}/bot#{telegram_cfg()[:token]}/sendMessage"
  end

  # telegram шлюз конфиг
  defp telegram_cfg(), do: Application.get_env(:sender, :telegram)

  # парсим ответ
  defp parse_answer({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    :ok
  end

  defp parse_answer({:ok, %HTTPoison.Response{status_code: _, body: body}}) do
    {:error, body}
  end

  defp parse_answer({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  # делаем лог и отправляем в mq статус
  defp log_and_send_to_mq(:ok, msg) do
    Logger.info("The msg #{inspect(msg)} was sent")
    Sender.MQ.Output.msg_sent(msg["id"])
  end

  defp log_and_send_to_mq({:error, err_msg}, msg) do
    Logger.error(err_msg)
    Sender.MQ.Output.msg_error(msg["id"])
  end
end
