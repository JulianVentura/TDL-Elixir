defmodule Main do
  require Entity
  require Room

  enemie1 = Entity.start_link(80, :rock)
  enemie2 = Entity.start_link(90, :paper)
  player1 = Entity.start_link(100, :paper)
  player2 = Entity.start_link(110, :scissors)
  room = Room.start_link()

  IO.inspect(Room.get_state(room))
  Room.add_enemie(room, enemie1)
  IO.inspect(Room.get_state(room))
  Room.add_enemie(room, enemie2)
  IO.inspect(Room.get_state(room))
  Room.add_player(room, player1)
  IO.inspect(Room.get_state(room))
  Room.add_player(room, player2)
  IO.inspect(Room.get_state(room))

  health = Room.attack_enemie(room, player1, enemie1, 10)
  IO.inspect(health)
  IO.inspect(Entity.get_state(enemie1))
  health = Room.attack_player(room, enemie1, player1, 10)
  IO.inspect(health)
  IO.inspect(Entity.get_state(player1))
end
