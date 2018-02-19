defmodule Sender.Core.Sms.MsgHandler do
  @moduledoc """
  Модуль отправки смс
  """
  require Logger

  # 5 повторов
  @repeat_count 5
  # 10 секунд
  @repeat_time 10_000

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> prepare_sms()
      |> send_sms(0)
      |> log_and_send_to_mq(msg)
    end)
  end

  # подготавливаем смс
  defp prepare_sms(msg) do
    [
      api_id: sms_cfg()[:api_key],
      to: msg["recipient"],
      msg: msg["msg"]["text"],
      json: 1,
      from: sms_cfg()[:from]
    ]
  end

  # смс шлюз конфиг
  defp sms_cfg(), do: Application.get_env(:sender, :sms)

  # отправка с повтором в случае ошибки
  defp send_sms(_sms, try_count) when try_count == @repeat_count do
    {:error, "Can't send sms after #{@repeat_count} tries"}
  end

  defp send_sms(sms, try_count) do
    case make_send_sms(sms) do
      {:ok, _} ->
        :ok

      {:error, err_msg} ->
        Logger.error(err_msg)
        :timer.sleep(@repeat_time)
        send_sms(sms, try_count + 1)
    end
  end

  # отправка и считывание ответа
  defp make_send_sms(sms) do
    url = send_sms_url()

    HTTPoison.get(url, [], params: sms)
    |> parse_body()
    |> parse_body_status_code()
    |> parse_sms_status_code()
  end

  # адрес АПИ для отправки смс
  defp send_sms_url() do
    "#{sms_cfg()[:api_url]}/send"
  end

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
  defp log_and_send_to_mq(:ok, msg) do
    Logger.info("The msg #{inspect(msg)} was sent")
    Sender.MQ.Output.msg_sent(msg["id"])
  end

  defp log_and_send_to_mq({:error, err_msg}, msg) do
    Logger.error(err_msg)
    Sender.MQ.Output.msg_error(msg["id"])
  end
end
