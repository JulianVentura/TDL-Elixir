defmodule World do
  require Room
  use GenServer

  # Public API

  def start_link(opts \\ []) do
    {_, world} = GenServer.start_link(__MODULE__, :ok, opts)
    world
  end

  def get_starting_room(world) do
    GenServer.call(world, :get_starting_room)
  end

  def get_neighbours(world, room) do
    GenServer.call(world, {:get_directions, room})
  end

  def get_neighbours(world, room, direction) do
    GenServer.call(world, {:get_room, room, direction})
  end

  # Handlers

  @impl true
  def init(:ok) do
    world = self()
    initial_state = File.stream!("./data/a.txt") 
    |> Stream.map(fn line -> String.trim(line) end) #Remove \n
    |> Stream.map(fn line -> String.split(line, ",") end)
    |> Enum.reduce({:digraph.new(), nil, %{}, %{}},
      fn args, acc ->
        {graph, iroom, room_state, pid_to_label} = acc
        [label, enemies_amount | connections] = args

        iroom = if iroom == nil do
          label
        end

        room_pid = Room.start_link(world)
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

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_starting_room, _from, {graph, iroom, room_state, pid_to_label}) do
    [iroom_pid | _] = Map.get(room_state, iroom)
    {:reply, iroom_pid, {graph, iroom, room_state, pid_to_label}}
  end

  @impl true
  def handle_call({:get_directions, room}, _from, {graph, iroom, room_state, pid_to_label}) do
    room_label = Map.get(pid_to_label, room)
    directions = :digraph.out_neighbours(graph, room_label)
    {:reply, directions, {graph, iroom, room_state, pid_to_label}}
  end

  @impl true
  def handle_call({:get_room, room, direction}, _from, {graph, iroom, room_state, pid_to_label}) do
    room_label = Map.get(pid_to_label, room)
    next_room_pid = if direction in :digraph.out_neighbours(graph, room_label) do
      [next_room_pid, _] = Map.get(room_state, direction)
      next_room_pid
    end
    {:reply, next_room_pid, {graph, iroom, room_state, pid_to_label}}
  end
  
end
