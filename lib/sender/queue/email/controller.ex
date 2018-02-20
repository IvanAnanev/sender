defmodule Sender.Queue.Email.Controller do
  use GenServer

  @change_time 10_000

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(_) do
    change()
    {:ok, %{pusher: Sender.Queue.Email.First, puller: Sender.Queue.Email.Second}}
  end

  def pusher(), do: GenServer.call(__MODULE__, :pusher)

  def puller(), do: GenServer.call(__MODULE__, :puller)

  def handle_cast(_, state), do: {:noreply, state}

  def handle_call(:pusher, _, %{pusher: pusher} = state), do: {:reply, pusher, state}
  def handle_call(:puller, _, %{puller: puller} = state), do: {:reply, puller, state}
  def handle_call(_, _, state), do: {:noreply, state}

  def handle_info(:change, %{pusher: pusher, puller: puller}) do
    change()
    {:noreply, %{pusher: puller, puller: pusher}}
  end

  defp change() do
    Process.send_after(self(), :change, @change_time)
  end
end