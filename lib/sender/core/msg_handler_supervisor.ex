defmodule Sender.Core.MsgHandlerSupervisor do
  use ConsumerSupervisor
  alias Sender.Core.{QueueHandler, MsgHandler}

  def start_link(_) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(MsgHandler, [], restart: :transient, shutdown: :infinity)
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{QueueHandler, max_demand: 100}]]
    ConsumerSupervisor.init(children, opts)
  end

end
