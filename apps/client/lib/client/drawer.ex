defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.clear()
    IO.puts(_draw_state(game_state))
  end

  defp _draw_state(state) do
    String.trim(
      """
      \n--- ESTADO DEL JUEGO ---
      #{format_enemy("\nEnemigos:")}
      #{if Enum.empty?(state.enemies) do
        format_enemy("No hay enemigos\n")
      else
        format_enemy(Enum.map(state.enemies, fn e -> "#{e.id} Vida: #{e.health} Tipo: #{e.stance} \n" end))
      end}
      """,
      "\n"
    ) <>
      String.trim(
        """
        #{format_player("\nJugadores:")}
        #{format_player(Enum.map(state.players, fn p -> "#{p.id} Vida: #{p.health} Tipo: #{p.stance} \n" end))}
        """,
        "\n"
      ) <>
      """
      #{format_turn("\nTurno:")}
      #{format_turn(state.turn)}
      #{format_room("\nDestinos:")}
      #{format_room(Enum.map(state.rooms, fn r -> "#{r} " end))}
      #{format_player("\nTu Jugador:")}
      #{format_player("#{state.player.id} Vida: #{state.player.health} Tipo: #{state.player.stance}")}
      \nComandos:
        attack <enemy>
        move <direction>
        exit

      Ingresa un comando:
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
