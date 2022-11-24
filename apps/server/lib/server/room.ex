defmodule Room do
  require Logger

  defmodule State do
    defstruct [:world, :enemies, :players, :turn, :turn_order, :type, :monitor]

    @type t() :: %__MODULE__{
            world: World.t(),
            enemies: list | nil,
            players: list | nil,
            turn: atom | nil,
            turn_order: map | nil,
            type: String.t(),
            monitor: any
          }
  end

  use GenServer
  # Public API

  @type world :: World.t()
  @type enemies :: list
  @type players :: list
  @type id :: pid | atom
  @type direction :: String.t()
  @type turn :: atom
  @type turn_order :: map

  @type key :: atom
  @type state_attribute :: world | enemies | players | turn | turn_order

  # Public API

  @spec start_link(world, integer, integer) :: pid
  def start_link(world, enemies_amount, flags) do
    {_, room} = GenServer.start_link(__MODULE__, {world, enemies_amount, flags})
    room
  end

  def attack(room, attacker, defender, amount, stance) do
    GenServer.call(room, {:attack, attacker, defender, amount, room, stance})
  end

  def move(room, player, direction) do
    GenServer.call(room, {:move, player, direction, room})
  end

  @spec add_enemie(id, id) :: atom()
  def add_enemie(room, enemie) do
    GenServer.call(room, {:add_enemie, enemie})
  end

  @spec add_player(id, id) :: atom()
  def add_player(room, player) do
    GenServer.call(room, {:add_player, player, room})
  end

  def get_state(room) do
    GenServer.call(room, :get_state)
  end

  # Handlers

  @impl true
  def init({world, enemies_amount, type}) do
    Logger.info("Starting Room of type #{type} from world #{inspect(world)}")
    room = self()
    enemies = EnemyCreator.create_enemies(type, room, enemies_amount)
    turn_order = enemies |> Enum.map(fn enemie -> {enemie, false} end) |> Map.new()
    monitor = Monitor.create()

    # Add enemies to monitor
    monitor =
      Enum.reduce(enemies, monitor, fn
        enem, mon -> Monitor.monitor(mon, enem)
      end)

    initial_state = %State{
      world: world,
      enemies: enemies,
      players: [],
      turn: :player,
      turn_order: turn_order,
      type: type,
      monitor: monitor
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:attack, attacker, defender, amount, room, stance}, _from, state) do
    {error, new_state} = _attack_handler(attacker, defender, amount, room, state, stance)
    {:reply, error, new_state}
  end

  @impl true
  def handle_call({:add_player, player, room}, _from, state) do
    Logger.info("Room #{inspect(self())}: Adding player #{inspect(player)}; type #{state.type}")

    %{
      world: world,
      players: players,
      enemies: enemies,
      turn_order: turn_order,
      turn: turn,
      type: type,
      monitor: monitor
    } = state

    new_state = if type == "exit" do
      Player.win(player)
      World.remove_player(world, player)
      state
    else
      turn_order =
        Map.put(
          turn_order,
          player,
          turn == :player and Enum.empty?(players)
        )

      players = players ++ [player]
      monitor = Monitor.monitor(monitor, player)
      Player.set_room(player, room)

      {player_turn, _} =
        turn_order |> Map.to_list() |> Enum.filter(fn {_player, turn} -> turn end) |> List.first() ||
          {nil, nil}

      _broadcast_game_state(true, player_turn, players, enemies, world)

      if type == "safe" do
        Player.heal(player)
      end

      %State{
         state
         | turn_order: turn_order,
           players: players,
           monitor: monitor
       }
    end
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:add_enemie, enemie}, _from, state) do
    %{
      enemies: enemies,
      turn_order: turn_order,
      turn: turn
    } = state

    enemies = enemies ++ [enemie]

    turn_order =
      Map.put(
        turn_order,
        enemie,
        turn == :enemie
      )

    {:reply, :ok, %State{state | turn_order: turn_order, enemies: enemies}}
  end

  @impl true
  def handle_call({:move, player, direction, room}, _from, state) do
    %{
      world: world,
      enemies: enemies
    } = state

    next_room = World.get_neighbours(world, room, direction)

    new_state =
      if next_room != nil and length(enemies) == 0 do
        Logger.info(
          "Room #{inspect(self())}: Moving player #{inspect(player)} to #{inspect(next_room)}"
        )

        new_state = _remove_player(player, state)
        Room.add_player(next_room, player)
        _broadcast_game_state(true, nil, new_state.players, new_state.enemies, new_state.world)
        new_state
      else
        state
      end

    error = next_room == nil or length(enemies) != 0

    msg =
      cond do
        next_room == nil -> "Invalid Direction"
        length(enemies) != 0 -> "There are enemies in the room"
        true -> "No error"
      end

    # TODO: Para qué devolvemos un mensaje si no hay error?
    {:reply,
     {if error do
        :error
      else
        :ok
      end, msg}, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:change_turn, attacker, attackees, defendees, turn}, state) do
    new_state = _change_turn(attacker, attackees, defendees, turn, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:attack, attacker, defender, amount, room}, state) do
    {_error, new_state} = _attack_handler(attacker, defender, amount, room, state, nil)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _}, state) do
    %{
      world: world,
      monitor: monitor,
      players: players,
      enemies: enemies,
      turn_order: turn_order,
      turn: turn
    } = state

    {pid, monitor} = Monitor.delete_by_ref(monitor, ref)

    Logger.info("Room #{inspect(self())}: DOWN message received, player/enemie #{inspect(pid)}")

    new_state =
      if (pid in players or pid in enemies) and turn_order[pid] do
        _change_turn(
          pid,
          players,
          enemies,
          if turn == :player do
            :enemie
          else
            :player
          end,
          state
        )
      else
        state
      end

    if pid in players do
      World.remove_player(world, pid)
    end

    turn_order = Map.delete(new_state.turn_order, pid)
    enemies = List.delete(new_state.enemies, pid)
    players = List.delete(new_state.players, pid)

    {player_turn, _} =
      turn_order
      |> Map.to_list()
      |> Enum.filter(fn {_player, turn} -> turn end)
      |> List.first() ||
        {nil, nil}

    _broadcast_game_state(true, player_turn, players, enemies, state.world)

    new_state2 = %{
      new_state
      | players: players,
        enemies: enemies,
        turn_order: turn_order,
        monitor: monitor
    }

    {:noreply, new_state2}
  end

  # Private functions

  def _attack_handler(attacker, defender, amount, room, state, stance) do
    %{
      players: players,
      enemies: enemies
    } = state

    cond do
      attacker in players and defender in enemies ->
        _attack_enemie(attacker, defender, amount, state, room, stance)

      attacker in enemies and defender in players ->
        {{:ok, "No Error"}, _attack_player(attacker, defender, amount, state, room)}

      true ->
        {{:error, "Invalid Attack"}, state}
    end
  end

  def _attack_enemie(player, enemie, amount, state, room, stance) do
    %{
      turn: turn,
      turn_order: turn_order,
      players: players
    } = state

    if turn == :player and turn_order[player] do
      Logger.info(
        "Room #{inspect(self())}: Player #{inspect(player)} is attacking enemie #{inspect(enemie)} with #{inspect(amount)}"
      )

      new_state = _attack(enemie, player, :player, amount, state, stance)

      %{
        enemies: enemies
      } = new_state

      GenServer.cast(room, {:change_turn, player, players, enemies, :enemie})
      {{:ok, "No Error"}, new_state}
    else
      {{:error, "Its not your turn"}, state}
    end
  end

  def _attack_player(enemie, player, amount, state, room) do
    %{
      turn: turn,
      turn_order: turn_order,
      enemies: enemies
    } = state

    Logger.info(
      "Room #{inspect(self())}: enemie #{inspect(enemie)} is attacking player #{inspect(player)} with #{inspect(amount)}"
    )

    if turn == :enemie and turn_order[enemie] do
      new_state = _attack(enemie, player, :enemie, amount, state, Enemie.get_stance(enemie))

      %{
        players: players
      } = new_state

      GenServer.cast(room, {:change_turn, enemie, enemies, players, :player})
      new_state
    else
      state
    end
  end

  def _attack(enemie, player, direction, amount, state, stance) do
    # Si direction es player, entonces player ataca a enemie, si no, enemie ataca a player
    case direction do
      :player ->
        health = Enemie.be_attacked(enemie, amount, stance)

        case health do
          0 -> _remove_enemie(enemie, state)
          _ -> state
        end

      :enemie ->
        health = Player.be_attacked(player, amount, stance)

        case health do
          0 -> _remove_player(player, state)
          _ -> state
        end
    end
  end

  def _change_turn(attacker, attackees, defendees, turn, state) do
    %{
      turn_order: turn_order
    } = state

    Logger.info(
      "Change turn #{inspect(self())}: Changing turn attacker #{inspect(attacker)} attackees #{inspect(attackees)} defendees #{inspect(defendees)} turn #{inspect(turn)}"
    )

    turn_order = Map.put(turn_order, attacker, false)

    change_turn = List.last(attackees) == attacker
    new_turn = if change_turn, do: turn, else: state.turn

    new_turn_order =
      case {change_turn, turn} do
        {true, :player} ->
          _broadcast_game_state(true, List.first(defendees), defendees, attackees, state.world)
          Map.put(turn_order, List.first(defendees), true)

        {true, :enemie} ->
          _broadcast_game_state(true, nil, attackees, defendees, state.world)

          for enemie <- defendees do
            %{player: player_to_attack, amount: amount} =
              Enemie.choose_player_to_attack(enemie, attackees)

            GenServer.cast(self(), {:attack, enemie, player_to_attack, amount, self()})
          end

          for d <- defendees, into: turn_order, do: {d, true}

        {false, turn} ->
          next_attacker =
            Enum.at(attackees, Enum.find_index(attackees, fn x -> x == attacker end) + 1)

          case turn do
            :player ->
              _broadcast_game_state(
                true,
                next_attacker,
                defendees,
                attackees,
                state.world
              )

            :enemie ->
              _broadcast_game_state(
                true,
                next_attacker,
                attackees,
                defendees,
                state.world
              )
          end

          Map.put(
            turn_order,
            next_attacker,
            true
          )
      end

    new_state = %State{state | turn: new_turn, turn_order: new_turn_order}

    new_state
  end

  def _broadcast_game_state(true, turn, players, enemies, world) do
    new_state = %{
      enemies: Enum.map(enemies, fn enemie -> {enemie, Enemie.get_state(enemie)} end),
      players: players,
      rooms: World.get_neighbours(world, self()),
      turn: turn
    }

    Enum.map(players, fn player -> Player.receive_state(player, new_state) end)
  end

  def _broadcast_game_state(_, _, _, _, _), do: :ok

  def _remove_enemie(enemie, state) do
    %{
      enemies: enemies,
      turn_order: turn_order
    } = state

    Enemie.stop(enemie)

    %State{
      state
      | turn_order: Map.delete(turn_order, enemie),
        enemies: List.delete(enemies, enemie)
    }
  end

  def _remove_player(player, state) do
    %{
      players: players,
      turn_order: turn_order,
      monitor: monitor
    } = state

    monitor = Monitor.demonitor(monitor, player)

    _broadcast_game_state(true, nil, players, state.enemies, state.world)

    %State{
      state
      | turn_order: Map.delete(turn_order, player),
        players: List.delete(players, player),
        monitor: monitor
    }
  end
end
