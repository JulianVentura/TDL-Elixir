defmodule Room do
  require Logger

  defmodule State do
    defstruct [:world, :enemies, :players, :turn, :turn_order, :type]

    @type t() :: %__MODULE__{
            world: World.t(),
            enemies: list | nil,
            players: list | nil,
            turn: atom | nil,
            turn_order: map | nil,
            type: String.t()
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

    initial_state = %State{
      world: world,
      enemies: enemies,
      players: [],
      turn: :player,
      turn_order: turn_order,
      type: type
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
      type: type
    } = state

    turn_order =
      Map.put(
        turn_order,
        player,
        turn == :player and Enum.empty?(players)
      )

    players = players ++ [player]

    Player.set_room(player, room)

    {player_turn, _} =
      turn_order |> Map.to_list() |> Enum.filter(fn {_player, turn} -> turn end) |> List.first()

    Logger.info("Broadcast")
    _broadcast_game_state(true, player_turn, players, enemies, world)
    Logger.info("Broadcast después")

    if type == "safe" do
      Player.heal(player)
    else
      if type == "exit" do
        Player.finish(player)
        # TODO: Revisar esto
        World.finish(world)
      end
    end

    {:reply, :ok, %State{state | turn_order: turn_order, players: players}}
  end

  @impl true
  def handle_call({:add_enemie, enemie}, _from, state) do
    %{
      players: _players,
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

  # Private functions

  def _attack_handler(attacker, defender, amount, room, state, stance) do
    %{
      players: players,
      enemies: enemies
    } = state

    # TODO: Esto se puede reemplazar por un cond (es más elixir) (incluso quizas con un case)
    if attacker in players and defender in enemies do
      {error, new_state} = _attack_enemie(attacker, defender, amount, state, room, stance)
      {error, new_state}
    else
      if attacker in enemies and defender in players do
        new_state = _attack_player(attacker, defender, amount, state, room)
        {{:ok, "No Error"}, new_state}
      else
        {{:error, "Invalid Attack"}, state}
      end
    end
  end

  def _attack_enemie(player, enemie, amount, state, room, stance) do
    %{
      turn: turn,
      turn_order: turn_order,
      players: players
    } = state

    if turn == :player and turn_order[player] do
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
    if direction == :player do
      health = Enemie.be_attacked(enemie, amount, stance)

      if health == 0 do
        _remove_enemie(enemie, state)
      else
        state
      end
    else
      health = Player.be_attacked(player, amount, stance)

      if health == 0 do
        _remove_player(player, state)
      else
        state
      end
    end
  end

  def _change_turn(attacker, attackees, defendees, turn, state) do
    %{
      turn_order: turn_order
    } = state

    turn_order = Map.put(turn_order, attacker, false)
    change_turn = List.last(attackees) == attacker

    new_turn = if change_turn, do: turn, else: state.turn

    new_turn_order =
      if change_turn do
        if turn == :enemie do
          _broadcast_game_state(true, nil, attackees, defendees, state.world)
          for d <- defendees, into: turn_order, do: {d, true}
        else
          _broadcast_game_state(true, List.first(defendees), defendees, attackees, state.world)
          Map.put(turn_order, List.first(defendees), true)
        end
      else
        next_attacker =
          Enum.at(attackees, Enum.find_index(attackees, fn x -> x == attacker end) + 1)

        _broadcast_game_state(
          new_turn,
          next_attacker,
          attackees,
          defendees,
          state.world
        )

        Map.put(
          turn_order,
          next_attacker,
          true
        )
      end

    if change_turn and turn == :enemie do
      for enemie <- defendees do
        %{player: player_to_attack, amount: amount} =
          Enemie.choose_player_to_attack(enemie, attackees)

        GenServer.cast(self(), {:attack, enemie, player_to_attack, amount, self()})
      end
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

    IO.inspect("Broadcast state: ")
    IO.inspect(new_state)

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
      turn_order: turn_order
    } = state

    %State{
      state
      | turn_order: Map.delete(turn_order, player),
        players: List.delete(players, player)
    }
  end
end
