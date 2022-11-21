defmodule IGameMaker do
  require GenServer # TODO: ver si esto anda

  # Public API
  def new_game(maker, client) do
    GenServer.call(maker, {:new_game, client})
  end
end
