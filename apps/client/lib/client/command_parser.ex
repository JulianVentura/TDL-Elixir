defmodule CommandParser do
  use Task

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    command =
      IO.gets("")
      |> String.trim()
      |> String.split(" ")

    _process_command(command)
    run()
  end

  defp _helper_text() do
    """
    \nComandos:
      atacar <enemigo> / a <enemigo>
      mover <destino> / m <destino>
      ayuda
      salir
    """
  end

  defp _process_command(command) do
    case command do
      ["atacar", enemy] -> _attack(enemy)
      ["a", enemy] -> _attack(enemy)
      ["mover", direction] -> _move(direction)
      ["m", direction] -> _move(direction)
      ["ayuda"] -> Drawer.draw_msg(_helper_text())
      ["salir"] -> _exit()
      _ -> Drawer.draw_msg("Comando inválido, si necesitas ayuda, escribe 'ayuda'")
    end
  end

  defp _attack(enemy) do
    ServerProxy.attack(ServerProxy, enemy)
  end

  defp _move(direction) do
    ServerProxy.move(ServerProxy, direction)
  end

  defp _exit() do
    Drawer.draw_msg("Gracias por jugar")
    System.stop(0)
  end
end
