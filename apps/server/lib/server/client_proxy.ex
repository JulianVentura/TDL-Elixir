defmodule ClientProxy do
  use GenServer, restart: :temporary
  require Logger

  # Client API

  def start_link(world, cli_addr, opts \\ []) do
    GenServer.start_link(__MODULE__, {world, cli_addr}, opts)
  end

  def attack(pid, enemy) do
    GenServer.call(pid, {:attack, enemy})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end
  
  def receive_state(pid, state) do
    GenServer.cast(pid, {:receive_state, state})
  end

  # GenServer API

  @impl true
  def init({world, cli_addr}) do
    Logger.info("Starting ClientProxy")
    player = Player.start_link("Jugador", 100, :paper, self())
    room = World.get_first_room(world)
    Room.add_player(room, player)

    {:ok, %{client: cli_addr, player: player, name_to_pid: %{}}}
  end

  @impl true
  def handle_call({:attack, enemy}, _from, state) do
    pid = Map.get(state.name_to_pid, enemy)
    Player.attack(state.player, pid)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:move, direction}, _from, state) do
    Player.move(state.player, direction)
    {:reply, direction, state}
  end

  @impl true
  def handle_cast({:receive_state, recv_state}, state) do
    %{
      enemies: enemies,
      players: players,
      turn: turn,
      rooms: rooms,
    } = recv_state
    
    players = Enum.map(players, fn player -> {player, Player.get_state(player)} end)

    name_to_pid = _update_state(players, enemies)  
    
    s_enemies = Enum.map(enemies, &_serialize_entity/1)
    s_players = Enum.map(players, &_serialize_entity/1) 
    s_player = 
      players
        |> Enum.filter(fn {pid, _} -> pid == state.player end)
        |> List.first
        |> _serialize_entity

    turn = 
      case turn do
        nil -> "No asignado"
        _ -> 
          Enum.concat(players, enemies) #TODO: Tiene sentido actualizar el estado si es el turno de un enemigo?
            |> Enum.filter(fn {pid, _} -> pid == turn end)
            |> List.first
            |> (fn p -> elem(p, 1).name end).()
      end

    send_state = %{
      turn: turn,
      player: s_player,
      players: s_players,
      enemies: s_enemies,
      rooms: rooms 
    }
    
    Logger.debug("Sending state to: #{inspect state.client}")
    Logger.debug(send_state)
     
    IServerProxy.receive_state(state.client, send_state)

    new_state = %{state | name_to_pid: name_to_pid}

    {:noreply, new_state}
  end

  defp _update_state(players, enemies) do
    Enum.concat(players, enemies)
      |> Enum.reduce(%{}, fn 
        (entity, name_to_pid) -> 
          pid = elem(entity, 0)
          name = elem(entity, 1).name
          Map.put(name_to_pid, name, pid)
      end) 
  end

  defp _serialize_entity(entity) do
    state = elem(entity, 1)
    %{
      id: state.name,
      health: state.health,
      stance: state.stance
    }
  end
end
