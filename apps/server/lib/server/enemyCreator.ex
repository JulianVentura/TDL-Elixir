defmodule EnemyCreator do
  require Enemie

  def create_enemies(room_type, room) do
    case room_type do
      :basic_room -> _create_basic_enemies(room)
      :boss_room -> _create_boss_enemies(room)
    end
  end

  def _create_basic_enemies(room) do
    enemies = [
      Enemie.start_link(1, :rock, room),
      Enemie.start_link(1, :rock, room),
      Enemie.start_link(1, :rock, room)
    ]

    enemies
  end

  def _create_boss_enemies(room) do
    enemies = [
      Enemie.start_link(1000, :rock, room)
    ]

    enemies
  end
end
