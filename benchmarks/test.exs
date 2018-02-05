list = Enum.to_list(1..10_000)

Benchee.run(%{
  "push_agent" => fn -> Sender.push_agent(list) end,
  "push_ets" => fn -> Sender.push_ets(list) end
}, time: 10, parallel: 2)