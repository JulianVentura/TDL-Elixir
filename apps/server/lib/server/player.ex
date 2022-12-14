defmodule Player do
  defmodule State do
    defstruct [:entity, :room, :client]

    @type t() :: %__MODULE__{
            entity: pid | atom | nil,
            room: pid | atom | nil,
            client: pid | atom | nil
          }
  end

  use GenServer
  # Public API

  @type name :: String.t()
  @type entity :: pid | atom
  @type id :: pid | atom
  @type health :: non_neg_integer()
  @type stance :: atom
  @type room :: pid | atom
  @type client :: pid | atom

  @type key :: atom
  @type state_attribute :: entity

  @spec start_link(name, health, stance, client) :: pid
  def start_link(name, health, initial_stance, client) do
    {_, player} = GenServer.start_link(__MODULE__, {name, health, initial_stance, client})
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

  @spec heal(id) :: integer
  def heal(player) do
    GenServer.cast(player, :heal)
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
  def attack(player, enemy) do
    GenServer.call(player, {:attack, player, enemy})
  end

  def move(player, direction) do
    GenServer.call(player, {:move, player, direction})
  end

  def receive_state(player, state_received, parse_player) do
    GenServer.cast(player, {:receive_state, state_received, parse_player})
  end

  def kill(player) do
    GenServer.cast(player, :kill)
  end

  def win(player) do
    GenServer.cast(player, :win)
  end

  def stop(player) do
    GenServer.cast(player, :stop)
  end

  @impl true
  def init({name, health, initial_stance, client}) do
    entity = Entity.start_link(name, health, initial_stance)
    state = %State{entity: entity, room: nil, client: client}

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    s = Entity.get_state(state.entity)
    {:reply, s, state}
  end

  @impl true
  def handle_call(:get_room, _from, state) do
    {:reply, state.room, state}
  end

  @impl true
  def handle_call(:get_stance, _from, state) do
    {:reply, Entity.get_state(state.entity).stance, state}
  end

  @impl true
  def handle_call({:be_attacked, amount, other_stance}, _from, state) do
    health = Entity.attack(state.entity, amount, other_stance)
    {:reply, health, state}
  end

  @impl true
  def handle_call({:attack, player, enemy}, _from, state) do
    {error, msg} =
      Room.attack(state.room, player, enemy, 10, Entity.get_state(state.entity).stance)

    {:reply, {error, msg}, state}
  end

  @impl true
  def handle_call({:move, player, direction}, _from, state) do
    res = Room.move(state.room, player, direction)
    {:reply, res, state}
  end

  @impl true
  def handle_cast(:kill, state) do
    ClientProxy.disconnect(state.client, :lose)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:win, state) do
    ClientProxy.disconnect(state.client, :win)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    Entity.stop(state.entity)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:heal, state) do
    Entity.heal(state.entity)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_room, room}, state) do
    new_state = %State{state | room: room}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:receive_state, state_received, parce_player}, state) do
    # TODO: Estar??a bueno que Player no dependa de ClientProxy
    # Se podr?? inyectar un callback para no tener que llamar explicitamente?
    ClientProxy.receive_state(state.client, state_received, parce_player)
    {:noreply, state}
  end
end
