defmodule Main do
  require Enemie
  require Room
  require Player

  enemie1 = Enemie.start_link(80, :rock)
  enemie2 = Enemie.start_link(90, :paper)
  player1 = Player.start_link(100, :paper)
  player2 = Player.start_link(110, :scissors)
  room = Room.start_link()

  IO.inspect(Player.get_state(player1))
  Room.add_enemie(room, enemie1)
  Room.add_enemie(room, enemie2)
  Room.add_player(room, player1)
  Room.add_player(room, player2)
  IO.inspect(Player.get_state(player1))
  IO.inspect(Room.get_state(room))

  IO.inspect(Player.attack(player1, enemie1, 10))
  IO.inspect(Room.get_state(room))
  IO.inspect(Player.attack(player2, enemie2, 10))
  IO.inspect(Room.get_state(room))
end
