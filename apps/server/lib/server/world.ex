defmodule World do
  require Room
  use GenServer, restart: :temporary
  require Logger

  # Public API
 
  def start_link(world_file_path, max_players) do
    GenServer.start_link(__MODULE__, {world_file_path, max_players})
  end

  def finish(world) do
    GenServer.cast(world, :finish)
  end

  def finished?(world) do
    GenServer.call(world, :finished?)
  end

  def full?(world) do
    GenServer.call(world, :full?)
  end

  def get_first_room(world) do
    GenServer.call(world, :get_first_room)
  end

  def add_player(world, player) do
    GenServer.call(world, {:add_player, player})
  end

  def remove_player(world, player) do
    GenServer.call(world, {:remove_player, player})
  end

  def get_neighbours(world, room) do
    GenServer.call(world, {:get_directions, room})
  end

  def get_neighbours(world, room, direction) do
    GenServer.call(world, {:get_room, room, direction})
  end

  def stop(world) do
    GenServer.stop(world, :normal, 5)
  end

  # Handlers

  @impl true
  def init({world_file_path, max_players}) do
    Logger.info("Starting World #{world_file_path} with #{max_players} player capacity")
    world = self()

    {graph, iroom, room_state, pid_to_label} =
      File.stream!(world_file_path)
      # Remove \n
      |> Stream.map(fn line -> String.trim(line) end)
      |> Stream.map(fn line -> String.split(line, ",") end)
      |> Enum.reduce(
        {:digraph.new(), nil, %{}, %{}},
        fn args, acc ->
          {graph, iroom, room_state, pid_to_label} = acc
          [label, enemies_amount, type | connections] = args

          iroom =
            if type == "start" do
              label
            else
              iroom
            end

          {enemies_amount, _} = Integer.parse(enemies_amount)

          room_pid = Room.start_link(world, enemies_amount, type)
          room_state = Map.put(room_state, label, [room_pid, enemies_amount])
          pid_to_label = Map.put(pid_to_label, room_pid, label)
          :digraph.add_vertex(graph, label)

          graph =
            Enum.reduce(connections, graph, fn other_label, graph ->
              :digraph.add_vertex(graph, other_label)
              :digraph.add_edge(graph, label, other_label)
              graph
            end)

          {graph, iroom, room_state, pid_to_label}
        end
      )

    state = %{
      graph: graph,
      iroom: iroom,
      room_state: room_state,
      pid_to_label: pid_to_label,
      max_players: max_players,
      players: 0,
      finished: false
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:finish, state) do
    new_state = %{state | finished: true}
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:finished?, _from, state) do
    {:reply, state.finished, state}
  end

  @impl true
  def handle_call(:full?, _from, state) do
    is_full = state.players == state.max_players
    {:reply, is_full, state}
  end

  @impl true
  def handle_call(:get_first_room, _from, state) do
    %{
      room_state: room_state,
      iroom: iroom
    } = state

    [iroom_pid | _] = Map.get(room_state, iroom)

    {:reply, iroom_pid, state}
  end

  @impl true
  def handle_call({:add_player, player}, _from, state) do
    Logger.info("World: Adding player #{inspect(player)}")

    %{
      room_state: room_state,
      iroom: iroom,
      players: players
    } = state

    [iroom_pid | _] = Map.get(room_state, iroom)
    Room.add_player(iroom_pid, player)

    new_state = %{state | players: players + 1}

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:remove_player, player}, _from, state) do
    Logger.info("World: Removing player #{inspect(player)}")
    new_state = %{state | players: state.players - 1, finished: state.players - 1 <= 0}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_directions, room}, _from, state) do
    %{
      pid_to_label: pid_to_label,
      graph: graph
    } = state

    room_label = Map.get(pid_to_label, room)
    directions = :digraph.out_neighbours(graph, room_label)
    {:reply, directions, state}
  end

  @impl true
  def handle_call({:get_room, room, direction}, _from, state) do
    %{
      pid_to_label: pid_to_label,
      graph: graph,
      room_state: room_state
    } = state

    room_label = Map.get(pid_to_label, room)

    next_room_pid =
      if direction in :digraph.out_neighbours(graph, room_label) do
        [next_room_pid, _] = Map.get(room_state, direction)
        next_room_pid
      end

    {:reply, next_room_pid, state}
  end
end
