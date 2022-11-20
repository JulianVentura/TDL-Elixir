defmodule Player do
  defmodule State do
    defstruct [:entity, :room]

    @type t() :: %__MODULE__{
            entity: pid | atom | nil,
            room: pid | atom | nil
          }
  end

  use GenServer
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
    {_, player} = GenServer.start_link(__MODULE__, {health, initial_stance})
    player
  end

  @spec get_state(id) :: Entity.State.t()
  def get_state(player) do
    GenServer.call(player, :get_state)
  end

  def get_room(player) do
    GenServer.call(player, :get_room)
  end

  @spec be_attacked(id, integer, stance) :: integer
  def be_attacked(player, amount, other_stance) do
    GenServer.call(player, {:be_attacked, amount, other_stance})
  end

  @spec get_stance(id) :: stance
  def get_stance(player) do
    GenServer.call(player, :get_stance)
  end

  @spec set_room(id, room) :: atom()
  def set_room(player, room) do
    GenServer.cast(player, {:set_room, room})
  end

  @spec attack(id, id) :: integer
  def attack(player, enemie) do
    GenServer.call(player, {:attack, player, enemie})
  end

  def move(player, direction) do
    GenServer.call(player, {:move, player, direction})
  end

  def receive_state(player, state_received) do
    GenServer.cast(player, {:receive_state, state_received})
  end

  @impl true
  def init({health, initial_stance}) do
    entity = Entity.start_link(health, initial_stance)
    state = %State{entity: entity, room: nil}

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.entity |> Entity.get_state(), state}
  end

  @impl true
  def handle_call(:get_room, _from, state) do
    {:reply, state.room, state}
  end

  @impl true
  def handle_call({:be_attacked, amount, other_stance}, _from, state) do
    health = Entity.attack(state.entity, amount, other_stance)
    {:reply, health, state}
  end

  @impl true
  def handle_call(:get_stance, _from, state) do
    {:reply, Entity.get_state(state.entity).stance, state}
  end

  @impl true
  def handle_call({:attack, player, enemie}, _from, state) do
    Room.attack(state.room, player, enemie, 10, Entity.get_state(state.entity).stance)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:move, player, direction}, _from, state) do
    Room.move(state.room, player, direction)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:set_room, room}, state) do
    new_state = %State{state | room: room}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:receive_state, _state_received}, state) do
    # TODO: Mandar nuevo estado a client proxy
    {:noreply, state}
  end
end
