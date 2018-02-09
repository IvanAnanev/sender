defmodule Sender.MQ.Input do
  @moduledoc """
    Обработка входящих сообщений MQ
  """
  use GenServer
  require Logger

  @resubscribe_time 15_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    # для безопасного отключения
    Process.flag(:trap_exit, true)
    # подписываемси
    GenServer.cast(self(), :subscribe)
    {:ok, %{}}
  end

  # Callbacks

  def handle_cast(:subscribe, state) do
    try do
      mq_input_topic() |> UtilMQ.sub()
      Logger.info("Subscribe MQ topic \"#{mq_input_topic()}\"")
    rescue
      _err ->
        Logger.warn("Problem with subscribe MQ topic \"#{mq_input_topic()}\"")
        :timer.apply_after(@resubscribe_time, GenServer, :cast, [__MODULE__, :subscribe])
    end

    {:noreply, state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  def handle_call(_, _, state), do: {:noreply, state}

  # получение и обработка сообщения
  def handle_info({:subscribed_publish, _topic, mq_msg}, state) do
    Logger.info("MQ input msg #{mq_msg}")

    mq_msg
    |> parse()
    |> validate()
    |> put_to_queue()

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  def terminate(reason, _state) do
    mq_input_topic() |> UtilMQ.usub()
    Logger.info("Unsubscribe MQ topic \"#{mq_input_topic()}\"")
    reason
  end

  # входящий канал mq topic
  defp mq_input_topic() do
    Application.get_env(:sender, :mq_input)
  end

  # парсим, если сломается, отловим в конце
  defp parse(mq_msg) do
    case Poison.decode(mq_msg) do
      {:ok, _} = result -> result
      {:error, _} -> {:error, "Can't parse #{mq_msg}"}
    end
  end

  # валидируем
  defp validate({:error, _} = e), do: e

  defp validate({:ok, msg_map}) do
    Sender.Helper.MsgValidator.exec(msg_map)
  end

  # ложим в очередь
  defp put_to_queue({:error, err_msg}), do: Logger.error(err_msg)

  defp put_to_queue({:ok, %{"type" => type, "priority" => priority} = msg}) do
    Logger.info("new message")
    Logger.info(inspect(msg))
  end
end
