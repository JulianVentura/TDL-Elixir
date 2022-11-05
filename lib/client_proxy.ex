defmodule ClientProxy do
  use GenServer

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: TempProxy)
  end

  def attack(pid, name) do
    GenServer.call(pid, {:attack, name})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # GenServer API

  @impl true
  def init(:ok) do
    player = "juan"
    {:ok, {player}}
  end

  @impl true
  def handle_call({:attack, attack}, _from, state) do
    {:reply, attack, state}
  end

  @impl true
  def handle_call({:move, direction}, _from, state) do
    {:reply, direction, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
