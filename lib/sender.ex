defmodule Sender do
  @moduledoc """
  Documentation for Sender.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Sender.hello
      :world

  """
  def hello do
    :world
  end

  def push_agent(list) do
    list
    |> Enum.each(fn x -> Sender.QueueAgent.push(rem(x, 100), x) end)

    # pull_agent()
  end

  def push_ets(list) do
    list
    |> Enum.each(fn x -> Sender.QueueEts2.push(rem(x, 100), x) end)

    # pull_ets()
  end

  defp pull_agent() do
    case Sender.QueueAgent.pull() do
      :empty -> :ok
      _ -> pull_agent()
    end
  end

  defp pull_ets() do
    case Sender.QueueEts2.pull() do
      :empty -> :ok
      _ -> pull_ets()
    end
  end
end
