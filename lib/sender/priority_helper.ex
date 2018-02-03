defmodule Sender.PriorityHelper do
  @priority_map %{
    "lowest" => 5,
    "low" => 4,
    "normal" => 3,
    "high" => 2,
    "highest" => 1,
  }

  def priority_index(priority) do
    @priority_map[priority]
  end
end
