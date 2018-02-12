defmodule Sender.Core.QueueHandler do
  @moduledoc """
  Обработчик очереди.
  Сделан на основе GenStage

  """

  use GenStage
  require Logger

  @repeat_time 5_000

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    shedule_work()
    {:producer, %{pending_demand: 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_info(:work, %{pending_demand: pending_demand}) do
    Logger.info("I am work!")
    dispatch_msgs(pending_demand, [])
  end

  def handle_demand(incoming_demand, %{pending_demand: pending_demand}) do
    dispatch_msgs(incoming_demand + pending_demand, [])
  end

  defp dispatch_msgs(0, msgs) do
    {:noreply, Enum.reverse(msgs), %{pending_demand: 0}}
  end

  defp dispatch_msgs(demand, msgs) do
    case Sender.Queue.Email.pull() do
      :empty ->
        shedule_work()
        {:noreply, Enum.reverse(msgs), %{pending_demand: demand}}
      msg ->
        dispatch_msgs(demand - 1, [msg | msgs])
    end
  end

  # регулярный опрос
  defp shedule_work() do
    Process.send_after(self(), :work, @repeat_time)
  end
end
