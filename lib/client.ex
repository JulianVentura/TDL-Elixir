defmodule Client do
  def game_loop() do
    game_state = ClientProxy.get_state(TempProxy)
    _draw(game_state)

    command =
      IO.gets(_helper_text())
      |> String.trim()
      |> String.split(" ")

    _process_command(command)
    game_loop()
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

  defp _draw(game_state) do
    IO.puts("\n--- ESTADO DEL JUEGO ---\n")
    IO.inspect(game_state)
    IO.puts("\n------------------------\n")
  end

  defp _process_command(command) do
    case command do
      ["attack", enemy] -> _attack(enemy)
      ["move", direction] -> _move(direction)
      ["exit"] -> _exit()
      _ -> IO.puts("Comando inválido, intenta otra vez")
    end
  end

  defp _attack(enemy) do
    IO.puts("Atacaste #{enemy}\n")
    ClientProxy.attack(TempProxy, enemy)
  end

  defp _move(direction) do
    IO.puts("Mover a dirección #{direction}")
    ClientProxy.move(TempProxy, direction)
  end

  defp _exit() do
    exit("Gracias por jugar")
  end
end
