defmodule Enemie do
  defmodule State do
    defstruct [:entity, :room]

    @type t() :: %__MODULE__{
            entity: pid | atom | nil,
            room: pid | atom | nil
          }
  end

  use Agent
  # Public API

  @type entity :: pid | atom
  @type id :: pid | atom
  @type health :: non_neg_integer()
  @type stance :: atom
  @type room :: pid | atom

  @type key :: atom
  @type state_attribute :: entity

  @spec start_link(health, stance) :: pid
  def start_link(health, initial_stance) do
    entity = Entity.start_link(health, initial_stance)
    state = %State{entity: entity, room: nil}

    {:ok, pid} =
      Agent.start_link(
        fn -> state end
        # Name is an atom that we can use to identify the Process without its PID. This is hardcoded, should be dynamic
      )

    pid
  end

  @spec get_state(id) :: State.t()
  def get_state(enemie) do
    _get_state(enemie)
  end

  @spec set_room(id, room) :: atom()
  def set_room(enemie, room) do
    _update_state(enemie, :room, room)
  end

  @spec be_attacked(id, integer, stance) :: integer
  def be_attacked(enemie, amount, other_stance) do
    %{
      entity: entity
    } = _get_state(enemie)

    Entity.attack(entity, amount, other_stance)
  end

  @spec get_stance(id) :: stance
  def get_stance(enemie) do
    %{
      entity: entity
    } = _get_state(enemie)

    Entity.get_state(entity).stance
  end

  @spec attack(id, id, integer) :: integer
  def attack(enemie, player, amount) do
    %{
      room: room
    } = _get_state(enemie)

    Room.attack(room, enemie, player, amount)
  end

  @spec choose_player_to_attack(pid, list) :: pid
  def choose_player_to_attack(enemie, players) do
    IA.choose_player_to_attack(players, :basic_ia)
  end

  @spec stop(id) :: atom()
  def stop(enemie) do
    Agent.stop(enemie)
  end

  # Private helper functions

  @spec _get_state(id) :: State.t()
  defp _get_state(enemie) do
    Agent.get(enemie, & &1)
  end

  @spec _get_state(id, key) :: state_attribute
  defp _get_state(enemie, key) do
    Agent.get(enemie, &Map.get(&1, key))
  end

  @spec _update_state(id, key, state_attribute()) :: atom()
  defp _update_state(enemie, key, value) do
    Agent.update(enemie, &Map.put(&1, key, value))
  end

  @spec _update_state(id, state_attribute()) :: atom()
  defp _update_state(enemie, state) do
    Agent.update(enemie, fn _ -> state end)
  end
end
