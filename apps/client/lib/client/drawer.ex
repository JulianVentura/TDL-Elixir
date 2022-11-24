defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.flush()
    IEx.Helpers.clear()
    lines = "\n--- ESTADO DEL JUEGO ---\n" <> inspect(game_state)

    lines =
      lines <>
        case arg do
          {"cmd", command} ->
            "\n---- ULTIMO COMANDO ----\n" <> inspect(command)

          {"err", error} ->
            "\n---- ERROR ----\n" <> inspect(error)

          _ ->
            ""
        end <> "\n------------------------\n" <> _helper_text()

    IO.puts(lines)
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
end
