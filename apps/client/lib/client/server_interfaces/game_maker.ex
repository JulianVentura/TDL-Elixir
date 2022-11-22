defmodule IGameMaker do
  # Public API
  def new_game(maker) do
    GenServer.call(maker, :new_game)
  end
end
