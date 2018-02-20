defmodule Sender.Queue.Pusher do
  @moduledoc """
  Модуль ложищий сообщение в очередь

  Вынесен в отдельный модуль из-за фичи отправки позднее.

  TODO: надо подумать о сохранение при выключение отсылаемых позже сообщений
  """
  use GenServer
  require Logger

  @queue_type_map %{
    "email" => Sender.Queue.Email.Controller,
    "sms" => Sender.Queue.Sms.Controller,
    "telegram" => Sender.Queue.Telegram.Controller,
    "wechat" => Sender.Queue.Wechat.Controller
  }

  @proirity_index_map %{
    "lowest" => 5,
    "low" => 4,
    "normal" => 3,
    "high" => 2,
    "highest" => 1,
  }

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(_), do: {:ok, %{}}

  # АПИ

  def exec(mq_msg), do: GenServer.cast(__MODULE__, {:push, mq_msg})

  # Callback

  def handle_cast({:push, %{"send_date" => send_date} = mq_msg}, state) do
    utc_now = DateTime.utc_now()
    {:ok, send_date_time, _} = DateTime.from_iso8601(send_date)
    diff = DateTime.to_unix(send_date_time) - DateTime.to_unix(utc_now)

    cond do
      diff <= 0 ->
        push(mq_msg)
      true ->
        # TODO: надо расширить логику для безопасного сохранения отправки сообщенй позже
        Process.send_after(self(), {:push_later, mq_msg}, diff * 1000)
    end

    {:noreply, state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  def handle_call(_, _, state), do: {:noreply, state}

  def handle_info({:push_later, mq_msg}, state) do
    push(mq_msg)

    {:noreply, state}
  end

  def handke_info(_, state), do: {:noreply, state}

  # ложим в очередь
  defp push(%{"type" => type, "priority" => priority} = mq_msg) do
    queue_for_type(type).push(priority_index(priority), mq_msg)
    # говорим MQ, что сообщение в очереди на отправку
    Sender.MQ.Output.msg_queued(mq_msg["id"])
  end

  # определяем очередь по типу
  defp queue_for_type(type) do
    @queue_type_map[type].pusher()
  end

  # определяем индекс приоритета
  # TODO: возможен более сложный механизм при числовом приоритете от 0 до 100
  defp priority_index(priority) do
    @proirity_index_map[priority]
  end
end