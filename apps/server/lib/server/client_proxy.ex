defmodule ClientProxy do
  use GenServer, restart: :temporary
  require Dmg
  require Logger

  # Client API

  def start_link(name, world, cli_addr, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, world, cli_addr}, opts)
  end

  def attack(pid, enemy) do
    GenServer.call(pid, {:attack, enemy})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end

  def receive_state(pid, state, parse_player) do
    GenServer.cast(pid, {:receive_state, state, parse_player})
  end

  def disconnect(pid, reason) do
    GenServer.cast(pid, {:disconnect, reason})
  end

  # GenServer API

  @impl true
  def init({name, world, cli_addr}) do
    Logger.info("Starting ClientProxy with name #{name}")
    players_amount = World.get_players_amount(world)
    stances = Dmg.get_stances()
    stance = Enum.at(stances, rem(players_amount, length(stances)))

    player =
      Player.start_link(name, Application.get_env(:entities, :player_health), stance, self())

    room = World.get_first_room(world)
    Room.add_player(room, player)
    World.add_player(world, player)
    ref = Process.monitor(cli_addr)

    {:ok, %{client: cli_addr, client_ref: ref, player: player, name_to_pid: %{}}}
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
  def handle_cast({:receive_state, recv_state, true}, state) do
    %{
      players: players
    } = recv_state

    players = Enum.map(players, fn player -> {player, Player.get_state(player)} end)

    new_state = _receive_state(players, recv_state, state)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:receive_state, recv_state, false}, state) do
    new_state = _receive_state(recv_state.players, recv_state, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:disconnect, reason}, state) do
    IServerProxy.disconnect(state.client, reason)
    Player.stop(state.player)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _}, state) do
    if ref == state.client_ref do
      Process.exit(self(), :kill)
    end

    {:noreply, state}
  end

  defp _receive_state(players, recv_state, state) do
    %{
      enemies: enemies,
      turn: turn,
      rooms: rooms
    } = recv_state

    name_to_pid = _update_state(players, enemies)

    s_enemies = Enum.map(enemies, &_serialize_entity/1)
    s_players = Enum.map(players, &_serialize_entity/1)

    s_player =
      players
      |> Enum.filter(fn {pid, _} -> pid == state.player end)
      |> List.first()
      |> _serialize_entity

    turn =
      case turn do
        nil ->
          "No asignado"

        _ ->
          # TODO: Tiene sentido actualizar el estado si es el turno de un enemigo?
          Enum.concat(players, enemies)
          |> Enum.filter(fn {pid, _} -> pid == turn end)
          |> List.first()
          |> (fn p -> elem(p, 1).name end).()
      end

    send_state = %{
      turn: turn,
      player: s_player,
      players: s_players,
      enemies: s_enemies,
      rooms: rooms
    }

    IServerProxy.receive_state(state.client, send_state)

    %{state | name_to_pid: name_to_pid}
  end

  defp _update_state(players, enemies) do
    Enum.concat(players, enemies)
    |> Enum.reduce(%{}, fn
      entity, name_to_pid ->
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
