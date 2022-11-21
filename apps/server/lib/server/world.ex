defmodule World do
  require Room
  use GenServer

  # Public API

  def start_link(world_file_path, max_players) do
    {_, world} = GenServer.start_link(__MODULE__, {world_file_path, max_players})
    world
  end

  def finish(world) do
    GenServer.call(world, :finish)
  end

  @impl true
  def handle_call(:finish, _from, {graph, iroom, room_state, pid_to_label, max_players, players, _}) do
    {:reply, :ok, {graph, iroom, room_state, pid_to_label, max_players, players, true}}
  end

  def finish?(world) do
    GenServer.call(world, :finish?)
  end

  @impl true
  def handle_call(:finish?, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    {:reply, finished, {graph, iroom, room_state, pid_to_label, max_players, players, finished}}
  end

  def full?(world) do
    GenServer.call(world, :full?)
  end

  @impl true
  def handle_call(:full?, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    {:reply, players == max_players, {graph, iroom, room_state, pid_to_label, max_players, players, finished}}
  end

  def add_player(world, player) do
    GenServer.call(world, {:add_player, player})
  end

  @impl true
  def handle_call({:add_player, player}, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    [iroom_pid | _] = Map.get(room_state, iroom)
    Room.add_player(iroom_pid, player)
    players = players + 1
    {:reply, :ok, {graph, iroom, room_state, pid_to_label, max_players, players, finished}}
  end

  def remove_player(world, player) do
    GenServer.call(world, {:remove_player, player})
  end

  @impl true
  def handle_call({:remove_player, player}, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    {:reply, :ok, {graph, iroom, room_state, pid_to_label, max_players, players - 1, finished}}
  end

  def get_neighbours(world, room) do
    GenServer.call(world, {:get_directions, room})
  end

  def get_neighbours(world, room, direction) do
    GenServer.call(world, {:get_room, room, direction})
  end

  # Handlers

  @impl true
  def init({world_file_path, max_players}) do
    world = self()
    {graph, iroom, room_state, pid_to_label} = File.stream!(world_file_path) 
    |> Stream.map(fn line -> String.trim(line) end) #Remove \n
    |> Stream.map(fn line -> String.split(line, ",") end)
    |> Enum.reduce({:digraph.new(), nil, %{}, %{}},
      fn args, acc ->
        {graph, iroom, room_state, pid_to_label} = acc
        [label, enemies_amount, type | connections] = args

        iroom = if type == "start" do label else iroom end

        {enemies_amount, _} = Integer.parse(enemies_amount)

        room_pid = Room.start_link(world, enemies_amount, type)
        room_state = Map.put(room_state, label, [room_pid, enemies_amount])
        pid_to_label = Map.put(pid_to_label, room_pid, label)
        :digraph.add_vertex(graph, label)

        graph = Enum.reduce(connections, graph, fn other_label, graph ->
          :digraph.add_vertex(graph, other_label)
          :digraph.add_edge(graph, label, other_label)
          graph
        end)

        {graph, iroom, room_state, pid_to_label}
      end)
    {:ok, {graph, iroom, room_state, pid_to_label, max_players, 0, false}}
  end

  @impl true
  def handle_call({:get_directions, room}, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    room_label = Map.get(pid_to_label, room)
    directions = :digraph.out_neighbours(graph, room_label)
    {:reply, directions, {graph, iroom, room_state, pid_to_label, max_players, players, finished}}
  end

  @impl true
  def handle_call({:get_room, room, direction}, _from, {graph, iroom, room_state, pid_to_label, max_players, players, finished}) do
    room_label = Map.get(pid_to_label, room)
    next_room_pid = if direction in :digraph.out_neighbours(graph, room_label) do
      [next_room_pid, _] = Map.get(room_state, direction)
      next_room_pid
    end
    {:reply, next_room_pid, {graph, iroom, room_state, pid_to_label, max_players, players, finished}}
  end
  
end
