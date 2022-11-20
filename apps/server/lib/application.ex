defmodule Server.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  require World

  @impl true
  def start(_type, _args) do
    children = [
      {ClientProxy, [name: TempProxy]}
      # Starts a worker by calling: Server.Worker.start_link(arg)
      # {Server.Worker, arg}
    ]

    #
    # player = Player.start_link(100, :rock)
    # player2 = Player.start_link(100, :rock)
    # world = World.start_link()
    # room = World.get_starting_room(world)
    #
    ## Aca se conecta un usuario, se agrega el usuario a la room y se le devuelve el pid del usuario
    # Room.add_player(room, player)
    # Room.add_player(room, player2)
    # %{enemies: enemies} = Room.get_state(room)
    #
    # IO.inspect(get_room_state(room, player))
    #
    # Player.attack(player, List.first(enemies))
    # IO.inspect(get_room_state(room, player))
    # :timer.sleep(1000)
    #
    # %{enemies: enemies2} = Room.get_state(room)
    # Player.attack(player2, List.first(enemies2))
    # IO.inspect(get_room_state(room, player))
    # :timer.sleep(1000)
    #
    # IO.inspect(get_room_state(room, player))

    #
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # defp get_room_state(room, player) do
  #  %{
  #    enemies: enemies,
  #    players: players,
  #    turn: turn,
  #    turn_order: turn_order
  #  } = Room.get_state(room)
  #
  #  state = %{
  #    :player => player,
  #    :turn => turn,
  #    :turn_order => turn_order,
  #    :enemies => _get_entities_state(enemies, &Enemie.get_state/1),
  #    :players => _get_entities_state(players, &Player.get_state/1)
  #  }
  # end
  #
  # defp _get_entities_state(entities, callback) do
  #  entities
  #  |> Enum.map(fn entity -> _serialize_entity_state(entity, callback) end)
  # end
  #
  # defp _serialize_entity_state(entity, callback) do
  #  state = callback.(entity)
  #
  #  {
  #    entity,
  #    state.health,
  #    state.stance
  #  }
  # end
end
