defmodule Entity do
  defmodule State do
    defstruct [:name, :max_health, :health, :stance]

    @type t() :: %__MODULE__{
            name: String.t(),
            max_health: non_neg_integer() | nil,
            health: non_neg_integer() | nil,
            stance: atom | nil
          }
  end

  use Agent
  # Public API

  @type name :: String.t()
  @type health :: non_neg_integer()
  @type stance :: atom
  @type id :: pid | atom

  @type key :: atom
  @type state_attribute :: health | stance

  @spec start_link(name, health, stance) :: pid
  def start_link(name, health, initial_stance) do
    state = %State{name: name, max_health: health, health: health, stance: initial_stance}

    {:ok, pid} =
      Agent.start_link(
        fn -> state end
        # Name is an atom that we can use to identify the Process without its PID. This is hardcoded, should be dynamic
      )

    pid
  end

  @spec get_state(id) :: State.t()
  def get_state(entity) do
    _get_state(entity)
  end

  @spec attack(id, integer, stance) :: integer
  def attack(entity, amount, other_stance) do
    %{
      health: health,
      stance: stance
    } = _get_state(entity)

    multiplier = Dmg.get_multiplier(stance, other_stance)
    damage = max(0, health - amount * multiplier)

    _update_state(entity, :health, damage)
    # Devuelve la nueva vida, no el daño recibido
    damage
  end

  @spec heal(id) :: atom()
  def heal(entity) do
    %{
      max_health: max_health,
    } = _get_state(entity)
    _update_state(entity, :health, max_health)
  end

  # Private helper functions

  @spec _get_state(id) :: State.t()
  defp _get_state(entity) do
    Agent.get(entity, & &1)
  end

  @spec _get_state(id, key) :: state_attribute
  defp _get_state(entity, key) do
    Agent.get(entity, &Map.get(&1, key))
  end

  @spec _update_state(id, key, state_attribute()) :: atom()
  defp _update_state(entity, key, value) do
    Agent.update(entity, &Map.put(&1, key, value))
  end

  @spec _update_state(id, state_attribute()) :: atom()
  defp _update_state(entity, state) do
    Agent.update(entity, fn _ -> state end)
  end
end
