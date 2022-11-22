defmodule Drawer do
  def draw(game_state, arg) do
    IEx.Helpers.clear
    IO.puts("\n--- ESTADO DEL JUEGO ---\n")
    IO.inspect(game_state)

    case arg do
      {"cmd", command} ->
        IO.puts("\n---- ULTIMO COMANDO ----\n")
        IO.puts(command)
      {"err", error} ->
        IO.puts("\n---- ERROR ----\n")
        IO.puts(error)
      _ -> ""
    end

    IO.puts("\n------------------------\n")
  end
end
