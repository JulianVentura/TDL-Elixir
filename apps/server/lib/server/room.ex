defmodule Room do
  defmodule State do
    defstruct [:world, :enemies, :players, :turn, :turn_order]

    @type t() :: %__MODULE__{
            world: World.t(),
            enemies: list | nil,
            players: list | nil,
            turn: atom | nil,
            turn_order: map | nil
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

  @spec start_link(world, integer) :: pid
  def start_link(world, enemies_amount) do
    {_, room} = GenServer.start_link(__MODULE__, {world, enemies_amount})
    room
  end

  def attack(room, attacker, defender, amount) do
    GenServer.call(room, {:attack, attacker, defender, amount, room})
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
  def init({world, enemies_amount}) do
    room = self()
    enemies = EnemyCreator.create_enemies(:basic_room, room, enemies_amount)
    turn_order = enemies |> Enum.map(fn enemie -> {enemie, false} end) |> Map.new()

    initial_state = %State{
      world: world,
      enemies: enemies,
      players: [],
      turn: :player,
      turn_order: turn_order
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:attack, attacker, defender, amount, room}, _from, state) do
    state = _attack_handler(attacker, defender, amount, room, state)
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_player, player, room}, _from, state) do
    %{
      players: players,
      enemies: _enemies,
      turn_order: turn_order,
      turn: turn
    } = state

    players = players ++ [player]

    turn_order =
      Map.put(
        turn_order,
        player,
        turn == :player
      )

    Player.set_room(player, room)
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
        Room.add_player(next_room, player)
        _remove_player(player, state)
      else
        state
      end

    {:reply, :ok, new_state}
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
    new_state = _attack_handler(attacker, defender, amount, room, state)
    {:noreply, new_state}
  end

  # Private functions

  def _attack_handler(attacker, defender, amount, room, state) do
    %{
      players: players,
      enemies: enemies
    } = state

    # TODO: Esto se puede reemplazar por un cond (es más elixir) (incluso quizas con un case)
    if attacker in players do
      _attack_enemie(attacker, defender, amount, state, room)
    else
      if attacker in enemies do
        _attack_player(attacker, defender, amount, state, room)
      else
        state
      end
    end
  end

  def _attack_enemie(player, enemie, amount, state, room) do
    %{
      turn: turn,
      turn_order: turn_order,
      players: players
    } = state

    if turn == :player and turn_order[player] do
      new_state = _attack(enemie, player, :player, amount, state)

      %{
        enemies: enemies
      } = new_state

      GenServer.cast(room, {:change_turn, player, players, enemies, :enemie})
      new_state
    else
      state
    end
  end

  def _attack_player(enemie, player, amount, state, room) do
    %{
      turn: turn,
      turn_order: turn_order,
      enemies: enemies
    } = state

    if turn == :enemie and turn_order[enemie] do
      new_state = _attack(enemie, player, :enemie, amount, state)

      %{
        players: players
      } = new_state

      GenServer.cast(room, {:change_turn, enemie, enemies, players, :player})
      new_state
    else
      state
    end
  end

  def _attack(enemie, player, direction, amount, state) do
    %{
      enemies: enemies,
      players: players
    } = state

    # Si direction es player, entonces player ataca a enemie, si no, enemie ataca a player
    health =
      if enemie in enemies and player in players do
        if direction == :player do
          Enemie.be_attacked(enemie, amount, Player.get_stance(enemie))
          # if health == 0, do: _remove_enemie(room, enemie)
          # health
        else
          Player.be_attacked(player, amount, Enemie.get_stance(player))
          # if health == 0, do: _remove_player(room, player)
          # health
        end
      else
        # Si no estan en la sala no deberian poder atacarse
        -1
      end

    # TODO: El codigo se podría refactorizar a como como está arriba (comentado).
    # Realmente no hace falta volver a preguntar acá la direction
    # Se que esto se ve horrible pero es la fomra correcta de hacerlo en elixir, las variables son inmutables, asi que no se puede cambiar el valor de una variable adentro de un if

    if health == 0 do
      if direction == :player do
        _remove_enemie(enemie, state)
      else
        _remove_player(player, state)
      end
    else
      state
    end
  end

  def _change_turn(attacker, attackees, defendees, turn, state) do
    %{
      turn_order: turn_order
    } = state

    turn_order = Map.put(turn_order, attacker, false)
    change_turn = List.foldl(attackees, true, fn x, acc -> acc and not turn_order[x] end)

    new_turn = if change_turn, do: turn, else: state.turn

    new_turn_order =
      if change_turn do
        for d <- defendees, into: turn_order, do: {d, true}
      else
        turn_order
      end

    if change_turn and turn == :enemie do
      for enemie <- defendees do
        %{player: player_to_attack, amount: amount} =
          Enemie.choose_player_to_attack(enemie, attackees)

        GenServer.cast(self(), {:attack, enemie, player_to_attack, amount, self()})
      end
    end

    %State{state | turn: new_turn, turn_order: new_turn_order}
  end

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

    Player.set_room(player, nil)

    %State{
      state
      | turn_order: Map.delete(turn_order, player),
        players: List.delete(players, player)
    }
  end
end
