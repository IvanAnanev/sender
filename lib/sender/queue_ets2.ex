defmodule Sender.QueueEts2 do
  use GenServer

  @table :queue_ets_2

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok ,name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [:ordered_set, :named_table])
    {:ok, %{}}
  end

  def push(priority_index, msg) do
    GenServer.cast(__MODULE__, {:push, priority_index, msg})
  end

  def pull() do
    GenServer.call(__MODULE__, :pull)
  end

  def handle_cast({:push, priority_index, msg}, state) do
    queue = case :ets.lookup(@table, priority_index) do
      [] -> :queue.in(msg, :queue.new())
      [{_, q}] -> :queue.in(msg, q)
    end
    :ets.insert(@table, {priority_index, queue})
    {:noreply, state}
  end

  def handle_call(:pull, _from, state) do
    response = case :ets.first(@table) do
      :"$end_of_table" -> :empty
      key ->
        [{_, queue}] = :ets.lookup(@table, key)
        {msg, new_queue} = :queue.out(queue)
        case :queue.is_empty(new_queue) do
          false -> :ets.insert(@table, {key, new_queue})
          true -> :ets.delete(@table, key)
        end
        msg
      end
    {:reply, response, state}
  end
end