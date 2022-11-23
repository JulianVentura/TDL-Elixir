defmodule IGameMaker do
  # Public API
  def new_game(maker, addr) do
    GenServer.call(maker, {:new_game, addr})
  end
end
