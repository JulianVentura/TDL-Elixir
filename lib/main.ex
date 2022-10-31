defmodule Main do
  require Enemie
  require Room
  require Player

  enemie1 = Enemie.start_link(80, :rock)
  enemie2 = Enemie.start_link(90, :paper)
  player1 = Player.start_link(100, :paper)
  player2 = Player.start_link(110, :scissors)
  room = Room.start_link()

  Room.add_enemie(room, enemie1)
  Room.add_enemie(room, enemie2)
  Room.add_player(room, player1)
  Room.add_player(room, player2)
  IO.inspect(Room.get_state(room))

  IO.inspect(Room.attack_enemie(room, player1, enemie1, 1000))
  IO.inspect(Room.get_state(room))
  IO.inspect(Room.attack_enemie(room, player2, enemie2, 10))
  IO.inspect(Room.get_state(room))
  IO.inspect(Room.attack_player(room, enemie1, player1, 10))
  IO.inspect(Room.get_state(room))
  IO.inspect(Room.attack_player(room, enemie2, player1, 10))
  IO.inspect(Room.get_state(room))
end
