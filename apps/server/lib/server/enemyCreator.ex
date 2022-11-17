defmodule EnemyCreator do
  require Enemie

  def create_enemies(room_type, room, amount) do
    case room_type do
      :basic_room -> _create_basic_enemies(room, amount)
      :boss_room -> _create_boss_enemies(room, amount)
    end
  end

  def _create_basic_enemies(room, amount) do
    for _ <- 0..amount do Enemie.start_link(1, :rock, room) end
  end

  def _create_boss_enemies(room, amount) do
    for _ <- 0..amount do Enemie.start_link(1000, :rock, room) end
  end
end
