defmodule Sender.Helper.MsgValidator do
  @moduledoc """
  Валидация входящего сообщения от MQ
  """
  require Logger

  @spec exec(msg :: map) :: {:ok, msg :: map} | {:error, err_msg :: String.t()}
  def exec(msg) do
    # в :errors будем складывать ошибки валидации
    %{msg: msg, errors: %{}}
    |> validate_id()
    |> validate_type()
    |> validate_recipient()
    |> validate_send_date()
    |> validate_priority()
    |> validate_msg()
    |> make_response()
  end

  # guard для type
  defguard is_msg_type(t) when t == "email" or t == "sms" or t == "telegram" or t == "wechat"

  # TODO: нужно переделать, при уточнении механизма приоритетов в ТендерПро
  # guard для priority
  defguard is_msg_priority(p)
            when p == "lowest" or p == "low" or p == "normal" or p == "high" or p == "highest"

  # валидация id
  defp validate_id(%{msg: %{"id" => id}} = rep_map) when is_bitstring(id), do: rep_map
  defp validate_id(rep_map), do: add_error(rep_map, "id", "it's bad")

  # валидация type
  defp validate_type(%{msg: %{"type" => type}} = rep_map) when is_msg_type(type), do: rep_map
  defp validate_type(rep_map), do: add_error(rep_map, "type", "it's bad")

  # валидация recipient
  defp validate_recipient(%{msg: %{"recipient" => recipient}} = rep_map)
       when is_bitstring(recipient),
       do: rep_map

  defp validate_recipient(rep_map), do: add_error(rep_map, "recipient", "it's bad")

  # валидация send_date
  defp validate_send_date(%{msg: msg} = rep_map) do
    case msg["send_date"] do
      nil ->
        rep_map

      date when is_bitstring(date) ->
        case DateTime.from_iso8601(date) do
          {:ok, datetime, _} -> rep_map
          err -> add_error(rep_map, "send_date", "can't parse datetime")
        end

      date ->
        add_error(rep_map, "send_date", "it's bad")
    end
  end

  # валидация priority
  defp validate_priority(%{msg: %{"priority" => priority}} = rep_map)
       when is_msg_priority(priority),
       do: rep_map

  defp validate_priority(rep_map), do: add_error(rep_map, "priority", "it's bad")

  # валидация msg
  defp validate_msg(%{msg: msg} = rep_map) do
    type = msg["type"]

    case msg["msg"] do
      %{"subject" => subj, "text" => text}
      when is_bitstring(text) and is_bitstring(subj) and type == "email" ->
        rep_map

      %{"text" => text} when is_bitstring(text) ->
        rep_map

      not_msg ->
        add_error(rep_map, "msg", "it's bad")
    end
  end

  # ответ
  defp make_response(%{msg: msg, errors: errors}) when map_size(errors) == 0, do: {:ok, msg}

  defp make_response(%{msg: msg, errors: errors}),
    do: {:error, "The msg #{inspect msg} have this errors: #{inspect errors}"}

  # добавить сообщение об ошибке в поле
  defp add_error(rep_map, error_key, error_msg) do
    errors = Map.put(rep_map.errors, error_key, error_msg)
    Map.put(rep_map, :errors, errors)
  end
end
