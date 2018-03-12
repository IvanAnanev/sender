defmodule Mix.Tasks.TestQueueSafeSave do
  @moduledoc """
    Тестируем работу очереди и безопасное сохранение при выключение
  """
  use Mix.Task
  require Logger
  alias Sender.Queue.Email.First, as: Queue

  @shortdoc "test queue safe save"
  def run(_) do
    Logger.info "test queue safe save"

    # поднимаем очередь
    {:ok, queue_pid} = GenServer.start_link(Queue, [])

    # ложим в очередь сообщения
    GenServer.call(queue_pid, {:push, 55, "55"})
    GenServer.call(queue_pid, {:push, 0, "0_1"})
    GenServer.call(queue_pid, {:push, 0, "0_2"})
    GenServer.call(queue_pid, {:push, 99, "99"})

    # гасим очередь с вызовом terminate
    GenServer.stop(queue_pid)

    # поднимаем очередь опять
    {:ok, restart_queue_pid} = GenServer.start_link(Queue, [])

    result = 1..5
      |> Enum.reduce([], fn(_x, acc) -> [GenServer.call(restart_queue_pid, :pull) | acc] end)
      |> Enum.reverse()

    case result do
      ["0_1", "0_2", "55", "99", :empty] ->
        Logger.info "Test good!"
        result |> inspect |> Logger.info
      _ ->
        Logger.error "Test bad!"
        result |> inspect |> Logger.error
    end

    GenServer.stop(restart_queue_pid)
  end
end