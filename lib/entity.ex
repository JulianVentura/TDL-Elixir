defmodule Entity do
  use Agent

  def start_link(health, initial_stance) do
    {:ok, entity} = Agent.start_link(fn -> %{:agent => [], :value => 0} end)
    Agent.update(entity, &Map.put(&1, "health", health))
    Agent.update(entity, &Map.put(&1, "stance", initial_stance))
    entity
  end

  def get_state(entity) do
    {Agent.get(entity, &Map.get(&1, "health")),
    Agent.get(entity, &Map.get(&1, "stance"))}
  end

  def attack(entity, amount, other_stance) do
    health = Agent.get(entity, &Map.get(&1, "health"))
    stance = Agent.get(entity, &Map.get(&1, "stance"))
    multiplier = Dmg.get_multiplier(stance, other_stance)
    damage = max(0, health - amount*multiplier)
    Agent.update(entity, &Map.put(&1, "health", damage))
    damage
  end
end
