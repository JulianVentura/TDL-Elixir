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

  @spec start_link(health, stance, pid) :: pid
  def start_link(health, initial_stance, room) do
    entity = Entity.start_link(health, initial_stance)
    state = %State{entity: entity, room: room}

    {:ok, pid} =
      Agent.start_link(
        fn -> state end
        # Name is an atom that we can use to identify the Process without its PID. This is hardcoded, should be dynamic
      )

    pid
  end

  def get_state(enemie) do
    enemie
    |> _get_state(:entity)
    |> Entity.get_state()
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

  @spec choose_player_to_attack(pid, list) :: pid
  def choose_player_to_attack(_enemie, players) do
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
  defp _get_state(player, key) do
    Agent.get(player, &Map.get(&1, key))
  end
end
