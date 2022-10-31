defmodule Player do
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
  def get_state(player) do
    _get_state(player)
  end

  @spec be_attacked(id, integer, stance) :: integer
  def be_attacked(player, amount, other_stance) do
    %{
      entity: entity
    } = _get_state(player)

    Entity.attack(entity, amount, other_stance)
  end

  @spec get_stance(id) :: stance
  def get_stance(player) do
    %{
      entity: entity
    } = _get_state(player)

    Entity.get_state(entity).stance
  end

  @spec set_room(id, room) :: atom()
  def set_room(player, room) do
    _update_state(player, :room, room)
  end

  @spec attack(id, id, integer) :: integer
  def attack(player, enemie, amount) do
    %{
      room: room
    } = _get_state(player)

    Room.attack_enemie(room, player, enemie, amount)
  end

  # Private helper functions

  @spec _get_state(id) :: State.t()
  defp _get_state(player) do
    Agent.get(player, & &1)
  end

  @spec _get_state(id, key) :: state_attribute
  defp _get_state(player, key) do
    Agent.get(player, &Map.get(&1, key))
  end

  @spec _update_state(id, key, state_attribute()) :: atom()
  defp _update_state(player, key, value) do
    Agent.update(player, &Map.put(&1, key, value))
  end

  @spec _update_state(id, state_attribute()) :: atom()
  defp _update_state(player, state) do
    Agent.update(player, fn _ -> state end)
  end
end
