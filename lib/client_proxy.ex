defmodule ClientProxy do
  use GenServer

  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:lookup, attack}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl true
  def handle_call({:lookup, move}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end
end
