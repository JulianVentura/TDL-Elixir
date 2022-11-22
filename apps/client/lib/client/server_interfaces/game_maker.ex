defmodule IGameMaker do
  # Public API
  def new_game(maker, client) do
    GenServer.call(maker, {:new_game, client})
  end
end
