defmodule Sender.Queue.EmailTest do
  use ExUnit.Case

  alias Sender.Queue.Email, as: Queue

  test "Priority Queue work" do
    assert Queue.pull() == :empty

    Queue.push(55, "55")
    Queue.push(0, "0_1")
    Queue.push(0, "0_2")
    Queue.push(99, "99")

    assert Queue.pull() == "0_1"
    assert Queue.pull() == "0_2"
    assert Queue.pull() == "55"
    assert Queue.pull() == "99"
    assert Queue.pull() == :empty
  end
end
