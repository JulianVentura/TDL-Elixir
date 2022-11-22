defmodule ClientProxy do
  use GenServer
  require Logger

  # Client API

  def start_link(world, opts \\ []) do
    GenServer.start_link(__MODULE__, world, opts)
  end

  def attack(pid, enemy) do
    GenServer.call(pid, {:attack, enemy})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end
  
  def hello_server(pid, client) do
    GenServer.call(pid, {:hello_server, client})
  end

  def receive_state(pid, state) do
    GenServer.cast(pid, {:receive_state, state})
  end

  # GenServer API

  @impl true
  def init(world) do
    Logger.info("Starting ClientProxy")
    player = Player.start_link(100, :paper, self())
    World.add_player(world, player)

    {:ok, {nil, player}}
  end
  
  @impl true
  def handle_call({:hello_server, client}, _from, {_, player}) do
    Logger.info("ClientProxy #{inspect self()}: Received hello_server")
    {:reply, :ok, {client, player}}
  end

  @impl true
  def handle_call({:attack, enemy}, _from, state) do
    Player.attack(state.player, enemy)
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
    
    s_enemies = _serialize_entities_state(enemies)
    s_players = _serialize_entities_state(players)
    s_player = List.first(Enum.filter(s_players, fn p_state -> p_state.id == state.player end))
    
    send_state = %{
      turn: turn,
      player: s_player,
      players: s_players,
      enemies: s_enemies,
      rooms: rooms 
    }
    
    IServerProxy.receive_state(state.client, send_state)

    {:noreply, state}
  end

  defp _serialize_entities_state(entities) do
    serialize_state = fn entity ->
      id = elem(entity, 0)  
      state = elem(entity, 1)
      
      %{
        id: id,
        health: state.health,
        stance: state.stance
      }
    end
    
    entities
      |> Enum.map(serialize_state)
  end
end
