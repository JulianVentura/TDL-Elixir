defmodule Client.Client do
  def game_loop(last_command \\ nil) do
    game_state = ClientProxy.get_state(TempProxy)
    _draw(game_state, last_command)

    command =
      IO.gets(_helper_text())
      |> String.trim()
      |> String.split(" ")

    cmd = _process_command(command)
    game_loop(cmd)
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

  defp _draw(game_state, cmd) do
    IEx.Helpers.clear
    IO.puts("\n--- ESTADO DEL JUEGO ---\n")
    IO.inspect(game_state)
    if cmd do 
      IO.puts("\n---- ULTIMO COMANDO ----\n")
      IO.puts(cmd)
    end
    IO.puts("\n------------------------\n")
  end

  defp _process_command(command) do
    case command do
      ["attack", enemy] -> _attack(enemy)
      ["move", direction] -> _move(direction)
      ["exit"] -> _exit()
      _ -> "Comando inválido, intenta otra vez\n"
    end
  end

  defp _attack(enemy) do
    ClientProxy.attack(TempProxy, IEx.Helpers.pid(enemy))
    "Atacaste #{enemy}\n"
  end

  defp _move(direction) do
    ClientProxy.move(TempProxy, direction)
    "Mover a dirección #{direction}\n"
  end

  defp _exit() do
    exit("Gracias por jugar")
  end
end
