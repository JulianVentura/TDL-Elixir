defmodule BroadCaster do
  require Logger

  def broadcast_game_state(:without_player_state, turn, players, enemies, world) do
    Logger.info("Broadcasting game state with players #{inspect(players)}")

    new_state = %{
      enemies: Enum.map(enemies, fn enemy -> {enemy, Enemy.get_state(enemy)} end),
      players: players,
      rooms: World.get_neighbours(world, self()),
      turn: turn
    }

    Enum.map(players, fn player -> Player.receive_state(player, new_state, true) end)
  end

  def broadcast_game_state(:with_player_state, turn, players, enemies, world) do
    Logger.info("Broadcasting game state with players #{inspect(players)}")

    new_state = %{
      enemies: Enum.map(enemies, fn enemy -> {enemy, Enemy.get_state(enemy)} end),
      players: Enum.map(players, fn player -> {player, Player.get_state(player)} end),
      rooms: World.get_neighbours(world, self()),
      turn: turn
    }

    Enum.map(players, fn player -> Player.receive_state(player, new_state, false) end)
  end

  def broadcast_game_state(dead_player, turn, players, enemies, world) do
    Logger.info("Broadcasting game state 2 with players #{inspect(players)}")

    new_state = %{
      enemies: Enum.map(enemies, fn enemy -> {enemy, Enemy.get_state(enemy)} end),
      players: players -- [dead_player],
      rooms: World.get_neighbours(world, self()),
      turn: turn
    }

    Enum.map(players, fn player -> Player.receive_state(player, new_state, true) end)
  end
end
