defmodule ClientProxy do
  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def attack(pid, name) do
    GenServer.call(pid, {:attack, name})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # GenServer API

  @impl true
  def init(:ok) do
    # Empieza el server, crea el usuario (por ahora lo harcodeamos asi luego se crearia al conectarse), crea el world y obtiene la start_room

    player = Player.start_link(100, :rock)
    world = World.start_link()
    room = World.get_starting_room(world)

    # Aca se conecta un usuario, se agrega el usuario a la room y se le devuelve el pid del usuario
    Room.add_player(room, player)

    {:ok, {player, room}}
  end

  @impl true
  def handle_call({:attack, enemy}, _from, {player, room}) do
    Player.attack(player, enemy)
    {:reply, :ok, {player, room}}
  end

  @impl true
  def handle_call({:move, direction}, _from, {player, _}) do
    Player.move(player, direction)
    room = Player.get_room(player)
    {:reply, direction, {player, room}}
  end

  @impl true
  def handle_call(:get_state, _from, {player, room}) do
    %{
      enemies: enemies,
      players: players,
      turn: turn
    } = Room.get_state(room)

    state = %{
      :player => player,
      :turn => turn,
      :enemies => _get_entities_state(enemies, &Enemie.get_state/1),
      :players => _get_entities_state(players, &Player.get_state/1)
    }

    {:reply, state, {player, room}}
  end

  # Optimization:
  # We could do something like a js wait_all.
  # Enemie and Player will have to provide an async_get_state
  # Then ClientProxy could implement a handle_info where it receives the responses
  defp _get_entities_state(entities, callback) do
    entities
    |> Enum.map(fn entity -> _serialize_entity_state(entity, callback) end)
  end

  defp _serialize_entity_state(entity, callback) do
    state = callback.(entity)

    {
      entity,
      state.health,
      state.stance
    }
  end
end
