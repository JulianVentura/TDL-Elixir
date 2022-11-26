defmodule CommandParser do
  # TODO: creo que con el use Task no es necesario
  # def child_spec(arg) do
  #   %{
  #     id: Client.Client,
  #     start: {Client.Client, :game_loop, [arg]}
  #   }
  # end

  use Task

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    command =
      IO.gets("")
      |> String.trim()
      |> String.split(" ")

    # TODO: ver como manejar en caso de comando erroneo, por proxy o acá con su respuesta
    _process_command(command)
    run()
  end

  defp _helper_text() do
    """
    \nComandos:
      attack <enemy>
      move <direction>
      help
      exit

    Ingresa un comando:
    """
  end

  defp _process_command(command) do
    case command do
      ["attack", enemy] -> _attack(enemy)
      ["move", direction] -> _move(direction)
      ["help"] -> IO.puts(_helper_text())
      ["exit"] -> _exit()
      _ -> IO.puts("Comando inválido, intenta otra vez\n")
    end
  end

  defp _attack(enemy) do
    ServerProxy.attack(ServerProxy, enemy)
  end

  defp _move(direction) do
    ServerProxy.move(ServerProxy, direction)
  end

  defp _exit() do
    # TODO: ver que hacer para salir
    exit("Gracias por jugar")
  end
end
