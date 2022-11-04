defmodule Main do
  # require Enemie
  # require Room
  require World
  require Player

  # enemie1 = Enemie.start_link(80, :rock)
  # enemie2 = Enemie.start_link(90, :paper)
  # player2 = Player.start_link(110, :scissors)
  # room = Room.start_link()
  # room2 = Room.start_link()
  # Room.add_enemie(room, enemie1)
  # Room.add_enemie(room, enemie2)
  # Room.add_player(room, player1)
  # IO.inspect(Room.get_state(room))
  # Room.add_player(room2, player2)
  # IO.inspect(Room.get_state(room2))
  # IO.inspect(Room.get_state(room))
  # IO.inspect(Player.get_state(player1))
  # IO.inspect(Room.get_state(room))
  # IO.inspect(Player.attack(player1, enemie1, 10))
  # IO.inspect(Room.get_state(room))
  # IO.inspect(Player.attack(player2, enemie2, 10))
  # IO.inspect(Room.get_state(room))

  player1 = Player.start_link(100, :paper)
  world = World.start_link()
  start_room = World.get_starting_room(world)
  Room.add_player(start_room, player1)
  IO.inspect(Player.get_state(player1))
  Room.move(start_room, player1, :N)
  IO.inspect(Player.get_state(player1))
end
