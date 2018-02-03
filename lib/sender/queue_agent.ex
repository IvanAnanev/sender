defmodule Sender.QueueAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def watch(), do: Agent.get(__MODULE__, fn state -> state end)

  def push(priority_index, msg) do
    Agent.update(__MODULE__, fn state ->
      index_queue = Map.get(state, priority_index, :queue.new())
      Map.put(state, priority_index, :queue.in(msg, index_queue))
    end)
  end

  def pull() do
    Agent.get_and_update(__MODULE__, fn state ->
      case Enum.fetch(state, 0) do
        {:ok, {priority_index, queue}} ->
            {msg, new_queue} = :queue.out(queue)
            case :queue.is_empty(new_queue) do
              false -> {msg, Map.put(state, priority_index, new_queue)}
              true -> {msg, Map.delete(state, priority_index)} # если очередь пустая, удаляем индекс приоритета из очереди
            end
        :error -> {:empty, %{}} # очередь пустая
      end
    end)
  end
end