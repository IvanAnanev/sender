defmodule Sender.Core.Base.MsgHandlerSupervisor do
  @moduledoc """
  Магия GenStage расшаренная через макрос.

  Объявление ConsumerSupervisor подписанного на QueueHandler
  :queue_handler - обработчик очереди на который подписывается ConsumerSupervisor
  :msg_handler - обраюотчик сообщения который будет запускаться
  :max_demand - количество обработчиков работающих одновременно

  Пример использования:

  module
    use Sender.Core.Base.MsgHandlerSupervisor,
      queue_handler: Sender.Core.Email.QueueHandler,
      msg_handler: Sender.Core.Email.MsgHandler,
      max_demand: 10

  app tree
    {Sender.Core.Email.MsgHandlerSupervisor, []}

  """
  defmacro __using__(opts) do
    quote location: :keep do
      use ConsumerSupervisor

      @queue_handler unquote(opts)[:queue_handler]
      @msg_handler unquote(opts)[:msg_handler]
      @max_demand unquote(opts)[:max_demand]

      def start_link(_) do
        ConsumerSupervisor.start_link(__MODULE__, :ok)
      end

      def init(:ok) do
        children = [
          worker(@msg_handler, [], restart: :transient, shutdown: :infinity)
        ]

        opts = [strategy: :one_for_one, subscribe_to: [{@queue_handler, max_demand: @max_demand}]]
        ConsumerSupervisor.init(children, opts)
      end
    end
  end
end
