defmodule GameMaker do
  use GenServer

  # Public API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def new_game(maker, client) do
    GenServer.call(maker, {:new_game, client})
  end

  # Server API

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:new_game, client}, _from, sessions) do
    # Spawnear nuevo GameSession
    # Spawnear nuevo ClientProxy
    

  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DB.Registry: #{msg}")
    {:noreply, state}
  end
end
