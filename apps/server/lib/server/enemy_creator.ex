defmodule EnemyCreator do
  require Dmg
  require Enemie
  require Logger

  defp _create_enemies(room, amount, base_name, min_health, max_health, stances) do
    if amount > 0 do
      for i <- 0..(amount - 1) do
        name = base_name <> "-" <> Integer.to_string(i)
        health = Enum.random(min_health..max_health)
        stance = Enum.random(stances)
        
        child_specs = %{
          id: Enemie,
          start: {Enemie, :start_link, [name, health, stance, room]},
          restart: :temporary,
          type: :worker
        }
        
        {:ok, pid} = DynamicSupervisor.start_child(EnemySupervisor, child_specs)
        Logger.debug("Spawned enemy #{name} with pid #{inspect pid}")
        pid
      end
    else
      []
    end
  end

  def create_enemies(room_type, room, amount) do
    stances = Dmg.get_stances()
    IO.inspect(stances)
    case room_type do
      "outskirts" -> _create_enemies(room, amount, "Bandido", 10, 20, stances)
      "trap" -> _create_enemies(room, amount, "Automata", 15, 25, stances)
      "tomb" -> _create_enemies(room, amount, "Renacido", 30, 50, stances)
      "boss" -> _create_enemies(room, amount, "Vges-Gis", 50, 80, stances)
      "test" -> _create_enemies(room, amount, "Test", 1, 1, [:rock])
      _ -> _create_enemies(room, amount, "Goblin", 10, 20, stances)
    end
  end
end
