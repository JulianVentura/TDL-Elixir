defmodule Enemy do
  defmodule State do
    defstruct [:entity, :room, :ia_type]

    @type t() :: %__MODULE__{
            entity: pid | atom | nil,
            room: pid | atom | nil,
            ia_type: atom | nil
          }
  end

  use Agent
  # Public API

  @type name :: String.t()
  @type entity :: pid | atom
  @type id :: pid | atom
  @type health :: non_neg_integer()
  @type stance :: atom
  @type room :: pid | atom

  @type key :: atom
  @type state_attribute :: entity

  @spec start_link(name, health, stance, pid, atom) :: any
  def start_link(name, health, initial_stance, room, ia_type) do
    entity = Entity.start_link(name, health, initial_stance)
    state = %State{entity: entity, room: room, ia_type: ia_type}

    {:ok, pid} = Agent.start_link(fn -> state end)
    Room.add_enemy(room, pid)
    {:ok, pid}
  end

  def get_state(enemy) do
    enemy
    |> _get_state(:entity)
    |> Entity.get_state()
  end

  @spec be_attacked(id, integer, stance) :: integer
  def be_attacked(enemy, amount, other_stance) do
    %{
      entity: entity
    } = _get_state(enemy)

    Entity.attack(entity, amount, other_stance)
  end

  @spec get_stance(id) :: stance
  def get_stance(enemy) do
    %{
      entity: entity
    } = _get_state(enemy)

    Entity.get_state(entity).stance
  end

  @spec choose_player_to_attack(pid, list) :: map()
  def choose_player_to_attack(enemy, players) do
    ia_type = _get_state(enemy, :ia_type)
    IA.choose_player_to_attack(players, ia_type)
  end

  @spec stop(id) :: atom()
  def stop(enemy) do
    entity = _get_state(enemy, :entity)
    Entity.stop(entity)
    Agent.stop(enemy, :normal)
  end

  # Private helper functions

  @spec _get_state(id) :: State.t()
  defp _get_state(enemy) do
    Agent.get(enemy, & &1)
  end

  @spec _get_state(id, key) :: state_attribute
  defp _get_state(enemy, key) do
    Agent.get(enemy, &Map.get(&1, key))
  end
end
