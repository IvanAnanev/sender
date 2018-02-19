defmodule Sender.Queue.Base do
  @moduledoc """
  Sender.Queue.Ваse модуль содержит общую логику для очередей
  сообщений с приоритетом

  что б прикрутить:

    use Sender.Queue.Base, type: :some_type

  Очередь с приоритетом.
  Представляет из себя :ets таблицу :ordered_set
  в которой по integer ключу хранится :queue {[],[]}.
  Самый приоритетный ключ 0.
  Внутри каждого ключа очередь :queue {[],[]}.
  В случае если очередь пустеет индекс удаляется,
  и пустая очередь будет пустой таблицей.

  Чтобы положить в очередь:
    Sender.Queue.Ваse.push(priority_index, msg)

  Чтобы забрать:
    Sender.Queue.Ваse.pull()

  """
  defmacro __using__(opts) do
    quote location: :keep do
      # используем опцию shutdown: :infinity для механизма
      # сохранения очереди на диск при выключении
      use GenServer, shutdown: :infinity
      require Logger

      # прокидываем название
      @table :"#{unquote(opts)[:type]}_queue"

      def start_link(_) do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
      end

      def init(_) do
        # для ожидания стоп сигнала выключения
        Process.flag(:trap_exit, true)
        init_ets_table()
        {:ok, %{}}
      end

      # API

      # толкаем в нашу очередь сообщение msg по приоритету priority_index
      def push(priority_index, msg), do: GenServer.cast(__MODULE__, {:push, priority_index, msg})

      # забираем из нашей очереди msg
      def pull(), do: GenServer.call(__MODULE__, :pull, :infinity)

      # Callbacks

      def handle_cast({:push, priority_index, msg}, state) do
        queue =
          case :ets.lookup(@table, priority_index) do
            [] -> :queue.in(msg, :queue.new())
            [{_, q}] -> :queue.in(msg, q)
          end

        :ets.insert(@table, {priority_index, queue})
        {:noreply, state}
      end

      def handle_cast(_, state), do: {:noreply, state}

      def handle_call(:pull, _from, state) do
        response =
          case :ets.first(@table) do
            # очередь пуста
            :"$end_of_table" ->
              :empty

            key ->
              [{_, queue}] = :ets.lookup(@table, key)
              {{:value, msg}, new_queue} = :queue.out(queue)

              # в случае пустой очереди, удаляем ключ
              case :queue.is_empty(new_queue) do
                false -> :ets.insert(@table, {key, new_queue})
                true -> :ets.delete(@table, key)
              end

              msg
          end

        {:reply, response, state}
      end

      def handle_call(_, _, state), do: {:noreply, state}

      def handke_info(_, state), do: {:noreply, state}

      def terminate(reason, _state) do
        :ets.tab2file(@table, dump_file())
        Logger.info("Save #{@table} table in dump")
        reason
      end

      # инитим ets таблицу
      defp init_ets_table() do
        # загружаем из дампа
        case :ets.file2tab(dump_file()) do
          {:ok, _} ->
            Logger.info("Load #{@table} table from dump")
            :ok

          # при первом запуске создаем с нуля
          {:error, _} ->
            :ets.new(@table, [:ordered_set, :named_table])
            Logger.info("Create #{@table} table")
        end
      end

      # место хранения дампа
      defp dump_file do
        "#{Application.get_env(:sender, :queue_dump_folder)}/#{@table}"
        |> to_charlist()
      end
    end
  end
end
