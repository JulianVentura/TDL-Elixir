defmodule EnemyCreator do
  require Enemie

  defp _create_enemies(room, amount, base_name, min_health, max_health, stances) do
    if amount > 0 do
      for i <- 0..(amount - 1) do
        name = base_name <> " " <> Integer.to_string(i)
        health = Enum.random(min_health..max_health)
        stance = Enum.random(stances)
        Enemie.start_link(name, health, stance, room)
      end
    else
      []
    end
  end

  def create_enemies(room_type, room, amount) do
    case room_type do
      "outskirts" -> _create_enemies(room, amount, "Bandido", 10, 20, [:rock, :paper, :scissors])
      "trap" -> _create_enemies(room, amount, "Automata", 15, 25, [:rock, :paper, :scissors])
      "tomb" -> _create_enemies(room, amount, "Renacido", 30, 50, [:rock, :paper, :scissors])
      "boss" -> _create_enemies(room, amount, "Vges Gis", 200, 300, [:rock, :paper, :scissors])
      "test" -> _create_enemies(room, amount, "Test", 1, 1, [:rock])
      _ -> _create_enemies(room, amount, "Goblin", 10, 20, [:rock, :paper, :scissors])
    end
  end
end
