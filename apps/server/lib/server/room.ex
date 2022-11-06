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

  use Agent
  # Public API

  @type world :: World.t()
  @type enemies :: list
  @type players :: list
  @type id :: pid | atom
  @type direction :: atom
  @type turn :: atom
  @type turn_order :: map

  @type key :: atom
  @type state_attribute :: world | enemies | players | turn | turn_order

  @spec start_link(world) :: pid
  def start_link(world) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    enemies = EnemyCreator.create_enemies(:basic_room, pid)
    turn_order = enemies |> Enum.map(fn enemie -> {enemie, false} end) |> Map.new()

    state = %State{
      world: world,
      enemies: enemies,
      players: [],
      turn: :player,
      turn_order: turn_order
    }
  
    _update_state(pid, state) 

    pid
  end

  @spec attack(id, id, id, integer) :: integer
  def attack(room, attacker, defender, amount) do
    %{
      players: players,
      enemies: enemies
    } = _get_state(room)
    
    # TODO: Esto se puede reemplazar por un cond (es más elixir) (incluso quizas con un case)
    if attacker in players do
      _attack_enemie(room, attacker, defender, amount)
    else
      if attacker in enemies do
        _attack_player(room, attacker, defender, amount)
      else
        -1
      end
    end
  end

  @spec _attack_enemie(id, id, id, integer) :: integer
  def _attack_enemie(room, player, enemie, amount) do
    %{
      turn: turn,
      turn_order: turn_order,
      players: players
    } = _get_state(room)

    if turn == :player and turn_order[player] do
      health = _attack(room, enemie, player, :player, amount)

      %{
        enemies: enemies
      } = _get_state(room)

      _change_turn(room, player, players, enemies, :enemie)
      health
    else
      -1
    end
  end

  @spec _attack_player(id, id, id, integer) :: integer
  def _attack_player(room, enemie, player, amount) do
    %{
      turn: turn,
      turn_order: turn_order,
      enemies: enemies
    } = _get_state(room)

    if turn == :enemie and turn_order[enemie] do
      health = _attack(room, enemie, player, :enemie, amount)

      %{
        players: players
      } = _get_state(room)

      _change_turn(room, enemie, enemies, players, :player)
      health
    else
      -1
    end
  end

  @spec _attack(id, id, id, atom, integer) :: integer
  def _attack(room, enemie, player, direction, amount) do
    %{
      enemies: enemies,
      players: players
    } = _get_state(room)

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
        _remove_enemie(room, enemie)
      else
        _remove_player(room, player)
      end
    end

    health
  end

  @spec _change_turn(id, id, list, list, atom) :: :ok
  def _change_turn(room, attacker, attackees, defendees, turn) do
    %{
      turn_order: turn_order
    } = _get_state(room)

    turn_order = Map.put(turn_order, attacker, false)
    change_turn = List.foldl(attackees, true, fn x, acc -> acc and not turn_order[x] end)

    if change_turn do
      _update_state(room, :turn, turn)

      turn_order = for d <- defendees, into: turn_order, do: {d, true}
      _update_state(room, :turn_order, turn_order)

      if turn == :enemie do
        for enemie <- defendees do
          %{player: player_to_attack, amount: amount} =
            Enemie.choose_player_to_attack(enemie, attackees)

          _attack_player(room, enemie, player_to_attack, amount)
        end
      end
    else
      _update_state(room, :turn_order, turn_order)
    end
  end

  @spec get_state(id) :: State.t()
  def get_state(room) do
    _get_state(room)
  end

  @spec add_player(id, id) :: atom()
  def add_player(room, player) do
    %{
      players: players,
      enemies: _enemies,
      turn_order: turn_order,
      turn: turn
    } = _get_state(room)

    players = players ++ [player]

    turn_order =
      Map.put(
        turn_order,
        player,
        turn == :player
      )

    Player.set_room(player, room)
    _update_state(room, :turn_order, turn_order)
    _update_state(room, :players, players)
  end

  @spec add_enemie(id, id) :: atom()
  def add_enemie(room, enemie) do
    %{
      players: _players,
      enemies: enemies,
      turn: turn,
      turn_order: turn_order
    } = _get_state(room)

    enemies = enemies ++ [enemie]

    turn_order =
      Map.put(
        turn_order,
        enemie,
        turn == :enemie
      )

    _update_state(room, :turn_order, turn_order)
    _update_state(room, :enemies, enemies)
  end

  @spec _remove_enemie(id, id) :: atom()
  def _remove_enemie(room, enemie) do
    %{
      enemies: enemies,
      turn_order: turn_order
    } = _get_state(room)

    Enemie.stop(enemie)
    _update_state(room, :turn_order, Map.delete(turn_order, enemie))
    _update_state(room, :enemies, List.delete(enemies, enemie))
  end

  @spec _remove_player(id, id) :: atom()
  def _remove_player(room, player) do
    %{
      players: players,
      turn_order: turn_order
    } = _get_state(room)

    Player.set_room(player, nil)
    _update_state(room, :turn_order, Map.delete(turn_order, player))
    _update_state(room, :players, List.delete(players, player))
  end

  @spec move(id, id, direction) :: atom()
  def move(room, player, direction) do
    %{
      world: world,
      enemies: enemies
    } = _get_state(room)

    if length(enemies) == 0 do
      next_room = World.get_neighbours(world, room, direction)

      if next_room != nil do
        Room._remove_player(room, player)
        Room.add_player(next_room, player)
      end
    else
      # Error
    end
  end

  # Private helper functions

  @spec _get_state(id) :: State.t()
  defp _get_state(room) do
    Agent.get(room, & &1)
  end

  @spec _get_state(id, key) :: state_attribute
  defp _get_state(room, key) do
    Agent.get(room, &Map.get(&1, key))
  end

  @spec _update_state(id, key, state_attribute()) :: atom()
  defp _update_state(room, key, value) do
    Agent.update(room, &Map.put(&1, key, value))
  end

  @spec _update_state(id, state_attribute()) :: atom()
  defp _update_state(room, state) do
    Agent.update(room, fn _ -> state end)
  end
end
