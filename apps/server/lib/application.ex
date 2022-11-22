defmodule Server.Application do
  use Application
  require World

  @impl true
  def start(_type, _args) do
    children = [
      GameMaker
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
