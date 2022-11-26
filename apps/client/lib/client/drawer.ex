defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.clear()
    IO.puts(_draw_state(game_state))
  end

  defp _parse_stance(stance) do
    case stance do
      :fire -> IO.ANSI.format([:red, :bright, "F"])
      :water -> IO.ANSI.format([:blue, :bright, "A"])
      :plant -> IO.ANSI.format([:green, :bright, "P"])
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

  defp _parse_entities(players, enemies, player) do
    _fill("/", "-", "\\") <>
    "|#{String.pad_trailing("JUGADORES", 18)}| #{String.pad_trailing("ENEMIGOS", 18)}|\n" <>
    _fill("|", "-", "|") <>
    List.to_string(for i <- 0..max(length(players), length(enemies)) do
      p = if i < length(players) do Enum.at(players, i) else nil end
      e = if i < length(enemies) do Enum.at(enemies, i) else nil end
      parsed_p = _parse_entity(p)
      parsed_e = _parse_entity(e)
      parsed_p2 = 
      "|#{if p && p.id == player.id do "#{format_player(parsed_p)}" else parsed_p end}| #{parsed_e}|\n"
    end) <>
    _fill("\\", "-", "/")
  end

  defp _draw_state(state) do
      """
      #{format_turn("Turno: #{state.turn}")}
      #{_parse_entities(state.players, state.enemies, state.player)}
      #{format_room("Destinos: #{Enum.map(state.rooms, fn r -> "#{r} " end)}")}
      """
  end

  def draw_msg(msg) do
    IO.puts(msg)
  end

  defp format_enemy(enemy) do
    IO.ANSI.format([:red, :bright, enemy])
  end

  defp format_player(player) do
    IO.ANSI.format([:green, :bright, player])
  end

  defp format_turn(turn) do
    IO.ANSI.format([:yellow, :bright, turn])
  end

  defp format_room(room) do
    IO.ANSI.format([:blue, :bright, room])
  end
end
