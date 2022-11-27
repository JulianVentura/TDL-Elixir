defmodule EnemyCreator do
  require Dmg
  require Enemie
  require Logger

  defp _create_enemies(room, amount, {base_name, min_health, max_health}, stances) do
    if amount > 0 do
      for i <- 0..(amount - 1) do
        name = base_name <> "-" <> Integer.to_string(i)
        health = Enum.random(min_health..max_health)
        stance = Enum.random(stances)

        child_specs = %{
          id: Enemie,
          start: {Enemie, :start_link, [name, health, stance, room]},
          restart: :transient,
          type: :worker
        }

        {:ok, pid} = DynamicSupervisor.start_child(EnemySupervisor, child_specs)
        Logger.debug("Spawned enemy #{name} with pid #{inspect(pid)}")
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
      "outskirts" -> _create_enemies(room, amount, Application.get_env(:entities, :bandido), stances)
      "trap" -> _create_enemies(room, amount, Application.get_env(:entities, :automata), stances)
      "tomb" -> _create_enemies(room, amount, Application.get_env(:entities, :renacido), stances)
      "boss" -> _create_enemies(room, amount, Application.get_env(:entities, :vges_gis), stances)
      "test" -> _create_enemies(room, amount, {"Test", 1, 1}, [:fire])
      _ -> _create_enemies(room, amount, Application.get_env(:entities, :goblin), stances)
    end
  end
end
