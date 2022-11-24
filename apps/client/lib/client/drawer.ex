defmodule Drawer do
  def draw(game_state, arg) do
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
    #{if Enum.empty?(state.enemies) do
      "No hay enemigos"
    else
      Enum.map(state.enemies, fn e -> "#{e.id} #{e.health} #{e.stance} " end)
    end}
    \nJugadores:
    #{Enum.map(state.players, fn p -> "#{p.id} #{p.health} #{p.stance} " end)}
    \nTurno:
    #{state.turn}
    \nDestinos:
    #{Enum.map(state.rooms, fn r -> "#{r} " end)}
    \nJugador:
    #{state.player.id} #{state.player.health} #{state.player.stance}
    \nComandos:
      attack <enemy>
      move <direction>
      exit

    Ingresa un comando:
    """
  end
end
