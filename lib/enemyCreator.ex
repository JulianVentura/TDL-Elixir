defmodule EnemyCreator do
  require Enemie

  def create_enemies(room_type) do
    case room_type do
      :basic_room -> _create_basic_enemies()
      :boss_room -> _create_boss_enemies()
    end
  end

  def _create_basic_enemies() do
    enemies = [
      Enemie.start_link(1, :rock),
      Enemie.start_link(1, :rock),
      Enemie.start_link(1, :rock)
    ]

    enemies
  end

  def _create_boss_enemies() do
    enemies = [
      Enemie.start_link(1000, :rock)
    ]

    enemies
  end
end
