defmodule Sender.Core.Base.QueueHandler do
  @moduledoc """
  Магия GenStage расшаренная через макрос.

  Разгребает очередь :queue_module и закидывает в ConsumerSupervisor

  Переодический опрос через :shedule_time

  Пример использования:
  module
     use Sender.Core.Base.QueueHandler,
      shedule_time: 1_000,
      queue_module: Sender.Queue.Email

  app tree
      {Sender.Core.Email.QueueHandler, []},

  """
  defmacro __using__(opts) do
    quote location: :keep do
      use GenStage

      @shedule_time unquote(opts)[:shedule_time]
      @queue unquote(opts)[:queue_module]

      def start_link(_), do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

      def init(_) do
        {:producer, %{pending_demand: 0}, dispatcher: GenStage.BroadcastDispatcher}
      end

      def handle_info(:shedule, %{pending_demand: pending_demand}) do
        dispatch_msgs(pending_demand, [])
      end

      def handle_demand(incoming_demand, %{pending_demand: pending_demand}) do
        dispatch_msgs(incoming_demand + pending_demand, [])
      end

      defp dispatch_msgs(0, msgs) do
        {:noreply, Enum.reverse(msgs), %{pending_demand: 0}}
      end

      defp dispatch_msgs(demand, msgs) do
        case @queue.puller().pull() do
          :empty ->
            # очередь пуста, спросим о наличие сообщений через @shedule_time
            shedule()
            {:noreply, Enum.reverse(msgs), %{pending_demand: demand}}

          msg ->
            dispatch_msgs(demand - 1, [msg | msgs])
        end
      end

      # регулярный опрос через @shedule_time
      defp shedule() do
        Process.send_after(self(), :shedule, @shedule_time)
      end
    end
  end
end
