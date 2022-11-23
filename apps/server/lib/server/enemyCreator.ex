defmodule EnemyCreator do
  require Enemie

  defp _create_enemies(room, amount, base_name, min_health, max_health) do
    if amount > 0 do
      for i <- 0..(amount - 1) do
        name = base_name <> " " <> Integer.to_string(i)
        health = Enum.random(min_health..max_health)
        stance = Enum.random([:rock, :paper, :scissors])
        Enemie.start_link(name, health, stance, room)
      end
    else
      []
    end
  end

  def create_enemies(room_type, room, amount) do
    case room_type do
      "outskirts" -> _create_enemies(room, amount, "Bandido", 10, 20)
      "trap" -> _create_enemies(room, amount, "Automata", 15, 25)
      "tomb" -> _create_enemies(room, amount, "Renacido", 30, 50)
      "boss" -> _create_enemies(room, amount, "Vges Gis", 200, 300)
      _ -> _create_enemies(room, amount, "Goblin", 10, 20)
    end
  end
end