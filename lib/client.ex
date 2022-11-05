defmodule Client do
  def game_loop do
    command =
      IO.gets("Ingresa un comando: ")
      |> String.trim
      |> String.split(" ")
      |> Enum.map(&(String.to_atom(&1)))

    _process_command(command)
  end

  defp _process_command(command) do
    case command do
      [:attack, enemy] -> IO.puts("Al ataqueeeee, morite #{enemy}")
      [:move, room] -> IO.puts("Movete perri, vamo a la sala #{room}")
      _ -> IO.puts("Comando inválido, intenta otra vez")
    end
  end
end
