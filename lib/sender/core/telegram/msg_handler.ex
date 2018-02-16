defmodule Sender.Core.Telegram.MsgHandler do
  @moduledoc """
  Модуль отправки Telegram сообщения
  """
  require Logger

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> make_send_request()
      |> parse_answer()
      |> log_and_send_to_mq(msg)
    end)
  end

  # отправляем сообщение
  defp make_send_request(msg) do
    url = send_msg_url()
    telegram_msg = [
      chat_id: msg["recipient"],
      text: msg["msg"]["text"]
    ]
    HTTPoison.get(url, [], params: telegram_msg)
  end

  # адрес АПИ для запроса
  defp send_msg_url() do
    "#{telegram_cfg()[:api_url]}/bot#{telegram_cfg()[:token]}/sendMessage"
  end

  # telegram шлюз конфиг
  defp telegram_cfg(), do: Application.get_env(:sender, :telegram)

  # парсим ответ
  defp parse_answer({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    result = body |> Poison.decode!
    {:ok, result["result"]["message_id"]}
  end

  defp parse_answer({:ok, %HTTPoison.Response{status_code: _, body: body}}) do
    {:error, body}
  end

  defp parse_answer({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  # делаем лог и отправляем в mq статус
  defp log_and_send_to_mq({:ok, _}, msg) do
    Logger.info("The msg #{inspect(msg)} was sent")
    Sender.MQ.Output.msg_sent(msg["id"])
  end

  defp log_and_send_to_mq({:error, err_msg}, msg) do
    Logger.error(err_msg)
    Sender.MQ.Output.msg_error(msg["id"])
  end
end
