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

  def redirect(maker, addr) do
    GenServer.call(maker, {:redirect, addr})
  end

  # Server API

  @impl true
  def init(:ok) do
    max_clients = Application.get_env(:server, :max_clients)
    Logger.info("Starting GameMaker with #{max_clients} client capacity")
    {:ok, _} = ClientProxyMaker.start_link(max_clients)
    {:ok, []}
  end

  @impl true
  def handle_call({:new_game, cli_addr}, _from, worlds) do
      {result, new_state} =
        case ClientProxyMaker.full?(ClientProxyMaker) do
          true ->
            nodes = NodeDirectory.get_neighbors(NodeDirectory)
            r = redirect_request(cli_addr, nodes)
            {r, worlds}
          false -> set_new_game(worlds, cli_addr)
        end

      {:reply, result, new_state}
  end

  @impl true
  def handle_call({:redirect, cli_addr}, _from, worlds) do
      {result, new_state} =
        case ClientProxyMaker.full?(ClientProxyMaker) do
          true -> {:error, worlds}
          false -> set_new_game(worlds, cli_addr)
        end

      {:reply, result, new_state}
  end

  defp redirect_request(_, []) do
    :error
  end

  defp redirect_request(cli_addr, [addr | t]) do
    case GameMaker.redirect({GameMaker, addr}, cli_addr) do
      {:ok, result} -> {:ok, result}
      :error -> redirect_request(cli_addr, t)
    end
  end

  defp set_new_game(worlds, cli_addr) do

      spawn_if_necessary = fn
        [] ->
          Logger.info("GameMaker: Spawning a new world")
          child_specs = %{
            id: World,
            start: {World, :start_link, [Application.get_env(:server, :world_file), Application.get_env(:server, :world_max_players)]},
            restart: :temporary,
            type: :worker
          }
          {:ok, world} = DynamicSupervisor.start_child(WorldSupervisor, child_specs)
          [world]
        v ->
          Logger.info("GameMaker: Using an existing world")
          v
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

      {:ok, name} = ClientProxyMaker.new(ClientProxyMaker, selected_world, cli_addr)

      new_worlds = Enum.concat(full, not_full)

      {{:ok, {name, node()}}, new_worlds}
    end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in GameMaker: #{msg}")
    {:noreply, state}
  end
end
