defmodule Sender.QueueEts do
  use GenServer
  require Logger

  @table :queue_ets

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok ,name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [:set, :named_table])
    :ets.insert(@table, {@table, %{}})
    {:ok, %{}}
  end

  def watch() do
    [{@table, queue}] = :ets.lookup(@table, @table)
    queue
  end

  def push(priority_index, msg) do
    GenServer.cast(__MODULE__, {:push, priority_index, msg})
  end

  def pull() do
    GenServer.call(__MODULE__, :pull)
  end

  def handle_cast({:push, priority_index, msg}, state) do
    [{@table, queue}] = :ets.lookup(@table, @table)
    index_queue = Map.get(queue, priority_index, :queue.new())
    :ets.insert(@table, {@table, Map.put(queue, priority_index, :queue.in(msg, index_queue))})

    {:noreply, state}
  end
  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_call(:pull, _from, state) do
    [{@table, queue}] = :ets.lookup(@table, @table)
    response = case Enum.fetch(queue, 0) do
      {:ok, {priority_index, index_queue}} ->
          {msg, new_index_queue} = :queue.out(index_queue)
          case :queue.is_empty(new_index_queue) do
            false -> :ets.insert(@table, {@table, Map.put(queue, priority_index, new_index_queue)})
            true -> :ets.insert(@table, {@table, Map.delete(queue, priority_index)}) # если очередь пустая, удаляем индекс приоритета из очереди
          end
          msg
      :error -> :empty
    end

    {:reply, response, state}
  end
  def handle_call(_, _, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end