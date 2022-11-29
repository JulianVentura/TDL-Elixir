defmodule EnemyCreator do
  require Dmg
  require Enemy
  require Logger

  defp _create_enemies(room, amount, {base_name, min_health, max_health}, stances, ia_type) do
    if amount > 0 do
      for i <- 0..(amount - 1) do
        name = base_name <> "-" <> Integer.to_string(i)
        health = Enum.random(min_health..max_health)
        stance = Enum.random(stances)

        child_specs = %{
          id: Enemy,
          start: {Enemy, :start_link, [name, health, stance, room, ia_type]},
          restart: :transient,
          type: :worker
        }

        {:ok, pid} = DynamicSupervisor.start_child(EnemySupervisor, child_specs)
        Logger.debug("Spawned enemy #{name} with pid #{inspect(pid)}")
        pid
      end
    else
      []
    end
  end

  def create_enemies(room_type, room, amount) do
    stances = Dmg.get_stances()

    case room_type do
      "outskirts" ->
        _create_enemies(
          room,
          amount,
          Application.get_env(:entities, :outskirts),
          stances,
          :random_ia
        )

      "trap" ->
        _create_enemies(room, amount, Application.get_env(:entities, :trap), stances, :random_ia)

      "tomb" ->
        _create_enemies(room, amount, Application.get_env(:entities, :tomb), stances, :random_ia)

      "boss" ->
        _create_enemies(room, amount, Application.get_env(:entities, :boss), [:fire], :random_ia)

      "test" ->
        _create_enemies(room, amount, {"Test", 1, 1}, [:fire], :basic_ia)

      _ ->
        _create_enemies(room, amount, Application.get_env(:entities, :other), stances, :random_ia)
    end
  end
end
