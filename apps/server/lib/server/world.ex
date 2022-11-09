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
    GenServer.call(world, {:get_neighbours, room})
  end

  def get_neighbours(world, room, direction) do
    GenServer.call(world, {:get_neighbours, room, direction})
  end

  # Handlers

  @impl true
  def init(:ok) do
    world = self()
    graph = :digraph.new()
    :digraph.add_vertex(graph, "A")
    :digraph.add_vertex(graph, "B")
    :digraph.add_vertex(graph, "C")
    :digraph.add_edge(graph, "A", "B", :N)
    :digraph.add_edge(graph, "B", "A", :S)
    :digraph.add_edge(graph, "A", "C", :S)
    :digraph.add_edge(graph, "C", "A", :N)

    {pid_to_label, label_to_pid} = Enum.reduce(["A", "B", "C"], {%{}, %{}},
      fn label, acc ->
        {pid_to_label, label_to_pid} = acc
        room_pid = Room.start_link(world)
        label_to_pid = Map.put(label_to_pid, label, room_pid)
        pid_to_label = Map.put(pid_to_label, room_pid, label)
        {pid_to_label, label_to_pid}
      end)

    {:ok, {graph, pid_to_label, label_to_pid}}
  end

  @impl true
  def handle_call(:get_starting_room, _from, {graph, pid_to_label, label_to_pid}) do
    {:reply, Map.get(label_to_pid, "A"), {graph, pid_to_label, label_to_pid}}
  end

  @impl true
  def handle_call({:get_neighbours, room}, _from, {graph, pid_to_label, label_to_pid}) do
    room_label = Map.get(pid_to_label, room)
    neighbours = []
    neighbours = for edge <- :digraph.out_edges(graph, room_label) do
      {_,_,v2,_} = :digraph.edge(graph,edge)
      neighbour_pid = Map.get(label_to_pid, v2)
      [neighbour_pid | neighbours]
    end
    {:reply, neighbours, {graph, pid_to_label, label_to_pid}}
  end

  @impl true
  def handle_call({:get_neighbours, room, direction}, _from, {graph, pid_to_label, label_to_pid}) do
    room_label = Map.get(pid_to_label, room)
    neighbour = Enum.reduce(
      :digraph.out_edges(graph, room_label),
      nil,
      fn edge, acc ->
        {_,_,v2,label} = :digraph.edge(graph,edge)
        if label == direction do
          Map.get(label_to_pid, v2)
        else
          acc
        end
      end
    )
    {:reply, neighbour, {graph, pid_to_label, label_to_pid}}
  end
end
