defmodule Server.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  require World

  @impl true
  def start(_type, _args) do
    children = [
      {ClientProxy, [name: TempProxy]}
      # Starts a worker by calling: Server.Worker.start_link(arg)
      # {Server.Worker, arg}
    ]

    world = World.start_link()
    room = World.get_starting_room(world)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
