defmodule Sender.Core.Sms.MsgHandler do
  @moduledoc """
  Модуль отправки смс
  """
  require Logger

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> make_request_to_send()
      |> parse_body()
      |> parse_body_status_code()
      |> parse_sms_status_code()
      |> log_and_send_to_mq(msg)
    end)
  end

  # запрос к АПИ на отправку
  defp make_request_to_send(msg) do
    msg
    |> make_url()
    |> HTTPoison.get()
  end

  # адрес АПИ для запроса
  defp make_url(msg) do
    text = msg["msg"]["text"]
    recipient = msg["recipient"]
    url = sms_cfg()[:api_url]
    api_id = sms_cfg()[:api_key]
    from = sms_cfg()[:from]

    "#{url}/send?api_id=#{api_id}&to=#{recipient}&msg=#{URI.encode_www_form(text)}&json=1&from=#{
      from
    }"
  end

  # смс шлюз конфиг
  defp sms_cfg(), do: Application.get_env(:sender, :sms)

  # парсим ответ от АПИ
  defp parse_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Poison.decode(body) do
      {:ok, _} = result -> result
      {:error, _} -> {:error, "Can't parse #{inspect(body)}"}
    end
  end

  defp parse_body({:ok, %HTTPoison.Response{} = response}) do
    {:error, "Uncatched response: #{inspect(response)}"}
  end

  defp parse_body({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  # проверяем статус ответа
  defp parse_body_status_code({:error, _} = e), do: e

  defp parse_body_status_code({:ok, %{"status_code" => status_code} = decoded_body})
       when status_code in 100..103 do
    {:ok, sms_map(decoded_body), decoded_body["status_text"]}
  end

  defp parse_body_status_code({:ok, %{"status_code" => status_code} = decoded_body})
       when status_code == 201 do
    {:error, "Not enough money #{inspect(decoded_body["status_text"])}"}
  end

  defp parse_body_status_code({:ok, decoded_body}) do
    {:error, "Send sms error: #{inspect(decoded_body["status_text"])}"}
  end

  # проверяем статус отправки смс
  defp parse_sms_status_code({:error, _} = e), do: e

  defp parse_sms_status_code({:ok, %{"status_code" => status_code} = sms_map, _})
       when status_code in 100..103 do
    {:ok, sms_map["sms_id"]}
  end

  defp parse_sms_status_code({:ok, _, status_text}) do
    {:error, "Send sms error: #{inspect(status_text)}"}
  end

  defp sms_map(decoded_body) do
    [{_, sms_map}] = decoded_body |> Map.get("sms") |> Map.to_list()

    sms_map
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
