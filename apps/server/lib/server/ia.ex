defmodule IA do
  @type player :: pid | atom
  @type ia :: :basic_ia | :least_health_ia | :random_ia

  @spec choose_player_to_attack(list, ia) :: map
  def choose_player_to_attack(players, ia_type) do
    case ia_type do
      :basic_ia -> _basic_ia(players)
      :random_ia -> _random_ia(players)
      :least_health_ia -> _least_health_ia(players)
    end
  end

  @spec _basic_ia(list) :: map
  def _basic_ia(players) do
    %{player: players |> List.first(), amount: 10}
  end

  @spec _least_health_ia(list) :: map
  def _least_health_ia(players) do
    %{
      player:
        players
        |> Enum.sort_by(fn {_, player} -> player.health end)
        |> List.last(),
      amount: 10
    }
  end

  @spec _random_ia(list) :: map
  def _random_ia(players) do
    %{
      player:
        players
        |> Enum.random(),
      amount: 10
    }
  end
end
