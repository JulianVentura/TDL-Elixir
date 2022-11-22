defmodule IClientProxy do
  # Client API

  def attack(pid, name) do
    GenServer.call(pid, {:attack, name})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end
end
