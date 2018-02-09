defmodule Sender.MQ.Output do
  @moduledoc """
  модуль для работы с MQ по отправке сообщений со статусом
  """
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(_), do: {:ok, %{}}

  # API

  def msg_inprocess(msg_id), do: GenServer.cast(__MODULE__, {:send, msg_id, "inprocess"})

  def msg_queued(msg_id), do: GenServer.cast(__MODULE__, {:send, msg_id, "queued"})

  def msg_sent(msg_id), do: GenServer.cast(__MODULE__, {:send, msg_id, "sent"})

  def msg_read(msg_id), do: GenServer.cast(__MODULE__, {:send, msg_id, "read"})

  def msg_error(msg_id), do: GenServer.cast(__MODULE__, {:send, msg_id, "error"})

  # Callback

  def handle_cast({:send, msg_id, status}, state) do
    %{"id" => msg_id, "status" => status}
    |> encode()
    |> send()

    {:noreply, state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  def handle_call(_, _, state), do: {:noreply, state}

  def handle_info(_, state), do: {:noreply, state}

  # кодируем в json
  defp encode(msg_map), do: Poison.encode!(msg_map)

  # отправляем
  defp send(msg) do
    UtilMQ.pub(mq_output_topic(), msg)
    Logger.info("MQ output topic: \"#{mq_output_topic()}\" msg: \"#{msg}\" ")
  end

  # выходящий канал mq topic
  defp mq_output_topic(), do: Application.get_env(:sender, :mq_output)
end
