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

  @spec add_enemy(id, id) :: atom()
  def add_enemy(room, enemy) do
    GenServer.cast(room, {:add_enemy, enemy})
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
    EnemyCreator.create_enemies(type, room, enemies_amount)
    turn_order = Map.new()
    monitor = Monitor.create()

    initial_state = %State{
      world: world,
      enemies: [],
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
    Logger.info("Room #{inspect(self())}: Adding player #{inspect(player)}")

    %{
      world: world,
      players: players,
      enemies: enemies,
      turn_order: turn_order,
      turn: turn,
      type: type,
      monitor: monitor
    } = state

    new_state =
      if type == "exit" do
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
          turn_order
          |> Map.to_list()
          |> Enum.filter(fn {_player, turn} -> turn end)
          |> List.first() ||
            {nil, nil}

        BroadCaster.broadcast_game_state(
          :without_player_state,
          player_turn,
          players,
          enemies,
          world
        )

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

        BroadCaster.broadcast_game_state(
          :without_player_state,
          nil,
          new_state.players,
          new_state.enemies,
          new_state.world
        )

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
  def handle_cast({:add_enemy, enemy}, state) do
    %{
      enemies: enemies,
      players: players,
      world: world,
      turn_order: turn_order,
      turn: turn,
      monitor: monitor
    } = state

    enemies = enemies ++ [enemy]
    monitor = Monitor.monitor(monitor, enemy)

    turn_order =
      Map.put(
        turn_order,
        enemy,
        turn == :enemy
      )

    {player_turn, _} =
      turn_order
      |> Map.to_list()
      |> Enum.filter(fn {_player, turn} -> turn end)
      |> List.first() ||
        {nil, nil}

    BroadCaster.broadcast_game_state(
      :without_player_state,
      player_turn,
      players,
      enemies,
      world
    )

    {:noreply, %State{state | turn_order: turn_order, enemies: enemies, monitor: monitor}}
  end

  @impl true
  def handle_cast({:change_turn, attacker, attackees, defendees, turn}, state) do
    new_state = _change_turn(attacker, attackees, defendees, turn, state, false)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:attack, attacker, defender, amount, room}, state) do
    {_error, new_state} = _attack_handler(attacker, defender, amount, room, state, nil)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, :killed}, state) do
    %{
      world: world,
      monitor: monitor,
      players: players,
      enemies: enemies,
      turn_order: turn_order,
      turn: turn
    } = state

    monitor = Monitor.demonitor(monitor, pid)

    Logger.info("Room #{inspect(self())}: DOWN message received, player/enemy #{inspect(pid)}")

    if pid in players do
      World.remove_player(world, pid)
    end

    new_state =
      if (pid in players or pid in enemies) and turn_order[pid] do
        _change_turn(
          pid,
          players,
          enemies,
          if turn == :player do
            :enemy
          else
            :player
          end,
          state,
          true
        )
      else
        state
      end

    turn_order = Map.delete(new_state.turn_order, pid)
    enemies = List.delete(enemies, pid)
    players = List.delete(players, pid)

    {player_turn, _} =
      turn_order
      |> Map.to_list()
      |> Enum.filter(fn {_player, turn} -> turn end)
      |> List.first() ||
        {nil, nil}

    BroadCaster.broadcast_game_state(
      :without_player_state,
      player_turn,
      players,
      enemies,
      state.world
    )

    new_state2 = %{
      new_state
      | players: players,
        enemies: enemies,
        turn_order: turn_order,
        monitor: monitor
    }

    {:noreply, new_state2}
  end

  @impl true
  def handle_info({:DOWN, _, :process, _pid, _}, state) do
    # Do nothing
    {:noreply, state}
  end

  # Private functions

  def _attack_handler(attacker, defender, amount, room, state, stance) do
    %{
      players: players,
      enemies: enemies
    } = state

    cond do
      attacker in players and defender in enemies ->
        _attack_enemy(attacker, defender, amount, state, room, stance)

      attacker in enemies and defender in players ->
        {{:ok, "No Error"}, _attack_player(attacker, defender, amount, state, room)}

      true ->
        {{:error, "Invalid Attack"}, state}
    end
  end

  def _attack_enemy(player, enemy, amount, state, room, stance) do
    %{
      turn: turn,
      turn_order: turn_order,
      players: players
    } = state

    if turn == :player and turn_order[player] do
      Logger.info(
        "Room #{inspect(self())}: Player #{inspect(player)} is attacking enemy #{inspect(enemy)} with #{inspect(amount)}"
      )

      new_state = _attack(enemy, player, :player, amount, state, stance)

      %{
        enemies: enemies
      } = new_state

      GenServer.cast(room, {:change_turn, player, players, enemies, :enemy})
      {{:ok, "No Error"}, new_state}
    else
      {{:error, "Its not your turn"}, state}
    end
  end

  def _attack_player(enemy, player, amount, state, room) do
    %{
      turn: turn,
      turn_order: turn_order,
      enemies: enemies
    } = state

    Logger.info(
      "Room #{inspect(self())}: enemy #{inspect(enemy)} is attacking player #{inspect(player)} with #{inspect(amount)}"
    )

    if turn == :enemy and turn_order[enemy] do
      new_state = _attack(enemy, player, :enemy, amount, state, Enemy.get_stance(enemy))

      %{
        players: players
      } = new_state

      GenServer.cast(room, {:change_turn, enemy, enemies, players, :player})
      new_state
    else
      state
    end
  end

  def _attack(enemy, player, direction, amount, state, stance) do
    # Si direction es player, entonces player ataca a enemy, si no, enemy ataca a player
    case direction do
      :player ->
        health = Enemy.be_attacked(enemy, amount, stance)

        case health do
          0 -> _remove_enemy(enemy, state)
          _ -> state
        end

      :enemy ->
        health = Player.be_attacked(player, amount, stance)

        case health do
          0 ->
            r = _remove_player(player, state)
            Player.kill(player)
            World.remove_player(state.world, player)
            r

          _ ->
            state
        end
    end
  end

  def _change_turn(attacker, attackees, defendees, turn, state, is_dead) do
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
          BroadCaster.broadcast_game_state(
            :with_player_state,
            List.first(defendees),
            defendees,
            attackees,
            state.world
          )

          Map.put(turn_order, List.first(defendees), true)

        {true, :enemy} ->
          BroadCaster.broadcast_game_state(
            if is_dead do
              attacker
            else
              :with_player_state
            end,
            List.first(defendees),
            attackees,
            defendees,
            state.world
          )

          if not Enum.empty?(defendees) do
            enemy = List.first(defendees)

            %{player: player_to_attack, amount: amount} =
              Enemy.choose_player_to_attack(enemy, attackees)

            GenServer.cast(self(), {:attack, enemy, player_to_attack, amount, self()})
          end

          for d <- defendees, into: turn_order, do: {d, true}

        {false, turn} ->
          next_attacker =
            Enum.at(attackees, Enum.find_index(attackees, fn x -> x == attacker end) + 1)

          case turn do
            :player ->
              %{player: player_to_attack, amount: amount} =
                Enemy.choose_player_to_attack(next_attacker, defendees)

              GenServer.cast(self(), {:attack, next_attacker, player_to_attack, amount, self()})

              BroadCaster.broadcast_game_state(
                :with_player_state,
                next_attacker,
                defendees,
                attackees,
                state.world
              )

            :enemy ->
              BroadCaster.broadcast_game_state(
                if is_dead do
                  attacker
                else
                  :with_player_state
                end,
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

  def _remove_enemy(enemy, state) do
    %{
      enemies: enemies,
      turn_order: turn_order,
      monitor: monitor
    } = state

    Enemy.stop(enemy)

    monitor = Monitor.demonitor(monitor, enemy)

    %State{
      state
      | turn_order: Map.delete(turn_order, enemy),
        enemies: List.delete(enemies, enemy),
        monitor: monitor
    }
  end

  def _remove_player(player, state) do
    %{
      players: players,
      turn_order: turn_order,
      monitor: monitor
    } = state

    monitor = Monitor.demonitor(monitor, player)

    %State{
      state
      | turn_order: Map.delete(turn_order, player),
        players: List.delete(players, player),
        monitor: monitor
    }
  end
end
