defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.flush()
    IEx.Helpers.clear()
    IO.puts(_draw_state(game_state))
  end

  defp _helper_text() do
    """
    \nComandos:
      attack <enemy>
      move <direction>
      exit

    Ingresa un comando:
    """
  end

  defp _draw_state(state) do
    """
    \n--- ESTADO DEL JUEGO ---
    \nEnemigos:
    #{Enum.map(state.enemies, fn e -> "#{e.id} #{e.health} " end)}
    \nJugadores:
    #{Enum.map(state.players, fn p -> "#{p.id} #{p.health} " end)}
    \nTurno:
    #{state.turn}
    \nDestinos:
    #{Enum.map(state.rooms, fn r -> "#{r} " end)}
    \nJugador:
    #{state.player.id} #{state.player.health}
    \nComandos:
      attack <enemy>
      move <direction>
      exit

    Ingresa un comando:
    """
  end
end
