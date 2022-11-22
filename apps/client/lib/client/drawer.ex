defmodule Drawer do
  def draw(game_state, cmd, err) do
    IEx.Helpers.clear
    IO.puts("\n--- ESTADO DEL JUEGO ---\n")
    IO.inspect(game_state)
    if cmd do
      IO.puts("\n---- ULTIMO COMANDO ----\n")
      IO.puts(cmd)
    end
    if err do
      IO.puts("\n---- ERROR ----\n")
      IO.puts(err)
    end
    IO.puts("\n------------------------\n")
  end
end
