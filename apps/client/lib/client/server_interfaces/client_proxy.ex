defmodule IClientProxy do
  # Client API

  def hello_server(pid, client) do
    GenServer.call(pid, {:hello_server, client})
  end

  def attack(pid, name) do
    GenServer.call(pid, {:attack, name})
  end

  def move(pid, room) do
    GenServer.call(pid, {:move, room})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end
end
