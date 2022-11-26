defmodule Server.Application do
  use Application
  require World

  @impl true
  def start(_type, _args) do
    children = [
      ProcessKiller,
      GameMaker,
      {DynamicSupervisor, name: EnemySupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: WorldSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: ClientProxySupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
