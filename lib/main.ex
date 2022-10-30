defmodule Main do
  require Entity
  require Room

  enemie1 = Entity.start_link(80, :rock)
  # enemie2 = Entity.start_link(90, :paper)
  # player1 = Entity.start_link(100, :paper)
  # player2 = Entity.start_link(110, :scissors)
  room = Room.start_link()

  IO.inspect(Room.get_state(room))
  Room.add_enemie(room, enemie1)
  IO.inspect(Room.get_state(room))
  Room.add_enemie(room, enemie1)
  IO.inspect(Room.get_state(room))
  Room.add_player(room, enemie1)
  IO.inspect(Room.get_state(room))
  Room.add_player(room, enemie1)
  IO.inspect(Room.get_state(room))
end
