defmodule Room do
  defmodule State do
    defstruct [:enemies, :players]

    @type t() :: %__MODULE__{
            enemies: list | nil,
            players: list | nil
          }
  end

  use Agent
  # Public API

  @type enemies :: list
  @type players :: list
  @type id :: pid | atom

  @type key :: atom
  @type state_attribute :: enemies | players

  @spec start_link() :: pid
  def start_link() do
    state = %State{enemies: [], players: []}

    {:ok, pid} =
      Agent.start_link(
        fn -> state end,
        # Name is an atom that we can use to identify the Process without its PID. This is hardcoded, should be dynamic
        name: TestRoom
      )

    pid
  end

  @spec get_state(id) :: State.t()
  def get_state(room) do
    _get_state(room)
  end

  @spec add_player(id, id) :: atom()
  def add_player(room, player) do
    %{
      players: players,
      enemies: _enemies
    } = _get_state(room)

    players = players ++ [player]

    _update_state(room, :players, players)
  end

  @spec add_enemie(id, id) :: atom()
  def add_enemie(room, enemie) do
    %{
      players: _players,
      enemies: enemies
    } = _get_state(room)

    enemies = enemies ++ [enemie]

    _update_state(room, :enemies, enemies)
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
