defmodule Main do
  # require Enemie
  # require Room
  require World
  require Player

  # Empieza el server, crea el usuario (por ahora lo harcodeamos asi luego se crearia al conectarse), crea el world y obtiene la start_room

  player1 = Player.start_link(100, :paper)
  world = World.start_link()
  start_room = World.get_starting_room(world)

  # Aca se conecta un usuario, se agrega el usuario a la room y se le devuelve el pid del usuario

  Room.add_player(start_room, player1)

  # Luego de un comando para obtener enemigos se devuelve esto

  current_room = Player.get_state(player1).room
  %{enemies: enemies} = Room.get_state(current_room)

  # Luego de un comando para atacar se llama a esto

  Player.attack(player1, List.first(enemies), 10)
end
