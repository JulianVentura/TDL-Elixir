defmodule GameMaker do
  use GenServer
  require Logger

  # Public API
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: GameMaker)
  end

  def new_game(maker, addr) do
    GenServer.call(maker, {:new_game, addr})
  end

  # Server API

  @impl true
  def init(:ok) do
    max_clients = 20
    name_len = 24
    Logger.info("Starting GameMaker with #{max_clients} client capacity")
    {:ok, name_service} = NameService.start_link(max_clients, name_len)
    {:ok, {[], name_service}}
  end

  @impl true
  def handle_call({:new_game, cli_addr}, _from, {worlds, name_service}) do
      {result, new_state} = 
        case NameService.full?(name_service) do
          true -> {:error, {worlds, name_service}} # TODO: Here we should redirect the client to another machine or something like that
          false -> set_new_game(worlds, name_service, cli_addr) 
        end

      {:reply, result, new_state}
  end

  def set_new_game(worlds, name_service, cli_addr) do
      
      spawn_if_necessary = fn 
        [] -> 
          child_specs = %{
            id: World,
            start: {World, :start_link, ["./data/world_0.txt", 4]}
          }
          {:ok, world} = DynamicSupervisor.start_child(WorldSupervisor, child_specs)
          [world]  
        v -> v
      end

      full = 
        worlds
          |> Enum.filter(fn world -> !World.finished?(world) end) 
          |> Enum.filter(fn world -> World.full?(world) end)

      not_full = 
        worlds
          |> Enum.filter(fn world -> !World.finished?(world) end) 
          |> Enum.filter(fn world -> !World.full?(world) end)
          |> spawn_if_necessary.()
      
      # Clean finished
      worlds
        |> Enum.filter(fn world -> World.finished?(world) end) 
        |> Enum.map(fn world -> World.stop(world) end)

      selected_world = List.first not_full

      child_specs = %{
        id: ClientProxy,
        start: {ClientProxy, :start_link, [selected_world, cli_addr]}
      }
      
      {:ok, cpid} = DynamicSupervisor.start_child(ClientProxySupervisor, child_specs)

      {:ok, name} = NameService.register_process(name_service, cpid)

      new_worlds = Enum.concat(full, not_full)

      {{name, node()}, {new_worlds, name_service}}
    end
  
  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in GameMaker: #{msg}")
    {:noreply, state}
  end
end
