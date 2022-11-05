defmodule Client do
  def game_loop() do
    command =
      IO.gets(_helper_text())
      |> String.trim
      |> String.split(" ")
      |> Enum.map(&(String.to_atom(&1)))

    _process_command(command)
    game_loop()
  end

  defp _process_command(command) do
    case command do
      [:attack, enemy] -> IO.puts("Al ataqueeeee, morite #{enemy}")
      [:move, room] -> IO.puts("Movete perri, vamo a la sala #{room}")
      [:exit] -> exit("Gracias por jugar")
      _ -> IO.puts("Comando inválido, intenta otra vez")
    end
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
end
