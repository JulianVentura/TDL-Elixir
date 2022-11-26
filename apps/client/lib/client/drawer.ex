defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.clear()
    _draw_state(game_state)
  end

  defp _format_color(color, str) do
    "#{IO.ANSI.format([color, :bright, str])}"
  end

  defp _parse_stance(stance) do
    case stance do
      :fire -> _format_color(:red, "F")
      :water -> _format_color(:blue, "A")
      :plant -> _format_color(:green, "P")
      _ -> "-"
    end
  end

  defp _parse_entity(entity) do
    if entity do
      id = String.pad_trailing("#{entity.id}", 10)
      health = String.pad_trailing("#{entity.health}", 4)
      stance = _parse_stance(entity.stance)
      "#{id} #{health} #{stance} "

    else
      String.pad_trailing("", 18)
    end
  end

  defp _fill(left, fill, right) do
    "#{left}#{String.pad_trailing("", 38, fill)}#{right}\n"
  end

  defp _color_turn(turn_id, entity) do
    parsed = _parse_entity(entity)
    if entity && entity.id == turn_id do _format_color(:yellow, parsed) else parsed end
  end

  defp _color_is_player(player_id, entity, parsed) do
    if entity && entity.id == player_id do _format_color(:green, parsed) else parsed end
  end

  defp _parse_entities(players, enemies, player_id, turn_id) do
    _fill("/", "-", "\\") <>
    "|#{String.pad_trailing("JUGADORES", 18)}| #{String.pad_trailing("ENEMIGOS", 18)}|\n" <>
    _fill("|", "-", "|") <>
    List.to_string(for i <- 0..max(length(players), length(enemies)) do
      p = if i < length(players) do Enum.at(players, i) else nil end
      e = if i < length(enemies) do Enum.at(enemies, i) else nil end
      parsed_e = _color_turn(turn_id, e)
      parsed_p = _color_turn(turn_id, p)
      parsed_p = _color_is_player(player_id, p, parsed_p)
      "|#{parsed_p}| #{parsed_e}|\n"
    end) <>
    _fill("\\", "-", "/")
  end

  defp _draw_state(state) do
      IO.puts(_parse_entities(state.players, state.enemies, state.player.id, state.turn))
      
      if Enum.empty?(state.enemies) do
        IO.puts(_format_color(:blue,"Destinos: #{Enum.map(state.rooms, fn r -> "#{r} " end)}"))
      end
      
      IO.write("> ")
      if state.turn in Enum.map(state.enemies, fn e -> e.id end) do
        :timer.sleep(1500)
      end
  end

  def draw_msg(msg) do
    IO.puts(msg)
  end
end
