defmodule Sender.Core.Wechat.MsgHandler do
  @moduledoc """
  Модуль отправки Wechat сообщения
  """
  require Logger
  alias Sender.Core.Wechat.AccessToken

  # 5 повторов
  @repeat_count 5
  # 10 секунд
  @repeat_time 10_000

  def start_link(msg) do
    Task.start_link(fn ->
      msg
      |> prepare_msg()
      |> send_message(0)
      |> log_and_send_to_mq(msg)
    end)
  end

  # кодируем сообщение в требуемый wechat json
  defp prepare_msg(msg) do
    Poison.encode!(%{
      touser: msg["recipient"],
      msgtype: "text",
      text: %{
        content: msg["msg"]["text"]
      }
    })
  end

  # отправка с повтором в случае ошибки
  defp send_message(_msg_json, try_count) when try_count == @repeat_count do
    {:error, "Can't send message after #{@repeat_count} tries"}
  end

  defp send_message(msg_json, try_count) do
    case make_send_msg(msg_json) do
      :ok ->
        :ok

      {:error, err_msg} ->
        Logger.error(err_msg)
        :timer.sleep(@repeat_time)
        send_message(msg_json, try_count + 1)
    end
  end

  # отправка и чтение ответа
  defp make_send_msg(msg_json) do
    url = send_msg_url()
    header = [{"Content-type", "application/json"}]

    HTTPoison.post(url, msg_json, header, [])
    |> check_response()
    |> match_body()
  end

  # адрес АПИ wechat
  defp send_msg_url() do
    token = AccessToken.access_token()
    "#{wechat_api_url()}/message/custom/send?access_token=#{token}"
  end

  # конфиг wechat
  defp wechat_api_url() do
    Application.get_env(:sender, :wechat)[:api_url]
  end

  # проверяем ответ
  defp check_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    Poison.decode(body)
  end

  defp check_response({:ok, %HTTPoison.Response{body: body}}), do: {:error, body}
  defp check_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  # читаем ответ
  defp match_body({:ok, %{"errcode" => 0, "errmsg" => "ok"}}), do: :ok

  defp match_body({:ok, %{"errcode" => 40001}}) do
    AccessToken.refresh_token()
    {:error, "Need refresh token"}
  end

  defp match_body({:ok, %{"errmsg" => reason}}), do: {:error, reason}
  defp match_body({:error, reason}), do: {:error, reason}

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
