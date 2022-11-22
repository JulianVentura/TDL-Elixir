defmodule CommandParser do
  # TODO: creo que con el use Task no es necesario
  # def child_spec(arg) do
  #   %{
  #     id: Client.Client,
  #     start: {Client.Client, :game_loop, [arg]}
  #   }
  # end

  use Task

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run() do
    command =
      IO.gets(_helper_text())
      |> String.trim()
      |> String.split(" ")

    _process_command(command)
    run()
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

  defp _process_command(command) do
    case command do
      ["attack", enemy] -> _attack(enemy)
      ["move", direction] -> _move(direction)
      ["exit"] -> _exit()
      _ -> IO.puts("Comando inválido, intenta otra vez\n")
    end
  end

  defp _attack(enemy) do
    ServerProxy.attack(TempProxy, IEx.Helpers.pid(enemy))
    "Atacaste #{enemy}\n"
  end

  defp _move(direction) do
    ServerProxy.move(TempProxy, direction)
    "Mover a dirección #{direction}\n"
  end

  defp _exit() do
    # TODO: ver que hacer
    exit("Gracias por jugar")
  end
end
