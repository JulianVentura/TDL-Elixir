defmodule Client do
  def game_loop() do
    command =
      IO.gets(_helper_text())
      |> String.trim()
      |> String.split(" ")

    _process_command(command)
    game_loop()
  end

  defp _helper_text() do
    """
    Comandos:
      attack <enemy>
      move <room>
      exit

    Ingresa un comando:
    """
  end

  defp _process_command(command) do
    case command do
      ["attack", enemy] -> _attack(enemy)
      ["move", room] -> _move(room)
      ["exit"] -> _exit()
      _ -> IO.puts("Comando inválido, intenta otra vez")
    end
  end

  defp _attack(enemy) do
    IO.puts("Al ataqueeeee, morite #{enemy}")
  end

  defp _move(room) do
    IO.puts("Movete perri, vamo a la sala #{room}")
  end

  defp _exit() do
    exit("Gracias por jugar")
  end
end
