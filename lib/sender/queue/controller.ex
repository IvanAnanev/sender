defmodule Sender.Queue.Controller do
  @moduledoc """
  Sender.Queue.Controller модуль организующий двойную очередь.
  Решает проблему забитости процесса.
  В один и тот же период времени:
    - одна очередь работает только на прием
    - другая на раздачу
    - сохраняется персистентность
    - нет гонки

    что б прикрутить:

    use Sender.Queue.Controller,
      change_time: 10_000,
      first_queue: Sender.Queue.Email.First,
      second_queue: Sender.Queue.Email.Second
  """
  defmacro __using__(opts) do
    quote location: :keep do
      use GenServer

      @change_time unquote(opts)[:change_time]
      @first_queue unquote(opts)[:first_queue]
      @second_queue unquote(opts)[:second_queue]

      # Init

      def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

      def init(_) do
        change()

        # храним ссылки на принимающую и раздающую очереди
        {:ok, %{pusher: @first_queue, puller: @second_queue}}
      end

      # API

      # ссылка на принимающую очередь
      def pusher(), do: GenServer.call(__MODULE__, :pusher)

      # ссылка на раздающую очередь
      def puller(), do: GenServer.call(__MODULE__, :puller)

      # Callbacks

      def handle_cast(_, state), do: {:noreply, state}

      # только синхронные вызовы
      def handle_call(:pusher, _, %{pusher: pusher} = state), do: {:reply, pusher, state}
      def handle_call(:puller, _, %{puller: puller} = state), do: {:reply, puller, state}
      def handle_call(_, _, state), do: {:noreply, state}

      # меняем местами
      def handle_info(:change, %{pusher: pusher, puller: puller}) do
        change()
        {:noreply, %{pusher: puller, puller: pusher}}
      end

      # в определенный период меняем местами очереди
      defp change() do
        Process.send_after(self(), :change, @change_time)
      end
    end
  end
end
