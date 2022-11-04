defmodule World do
  require Room

  defmodule State do
    defstruct [:pid_to_label, :label_to_pid, :graph]

    @type t() :: %__MODULE__{
            pid_to_label: map | nil,
            label_to_pid: map | nil,
            graph: :digraph.t() | nil
          }
  end

  use Agent

  @type world_pid :: pid | atom
  @type room_pid :: pid | atom
  @type direction :: atom
  @type state_attribute :: map | map | :digraph.t()
  @type key :: atom

  @spec start_link() :: pid
  def start_link() do
    nil_state = %State{pid_to_label: nil, label_to_pid: nil, graph: nil}
    {:ok, pid} = Agent.start_link(fn -> nil_state end)

    gr = :digraph.new()

    :digraph.add_vertex(gr, "A")
    :digraph.add_vertex(gr, "B")
    :digraph.add_vertex(gr, "C")
    :digraph.add_edge(gr, "A", "B", :N)
    :digraph.add_edge(gr, "B", "A", :S)
    :digraph.add_edge(gr, "A", "C", :S)
    :digraph.add_edge(gr, "C", "A", :N)

    {pid_to_label, label_to_pid} = Enum.reduce(["A", "B", "C"], {%{}, %{}},
      fn label, acc ->
        {pid_to_label, label_to_pid} = acc
        room_pid = Room.start_link(pid)
        label_to_pid = Map.put(label_to_pid, label, room_pid)
        pid_to_label = Map.put(pid_to_label, room_pid, label)
        {pid_to_label, label_to_pid}
      end)
    
    state = %State{pid_to_label: pid_to_label, label_to_pid: label_to_pid, graph: gr}
    _update_state(pid, state)
    pid
  end

  @spec get_starting_room(world_pid) :: room_pid
  def get_starting_room(world) do
    %{
      pid_to_label: _,
      label_to_pid: label_to_pid,
      graph: _
    } = _get_state(world)
    Map.get(label_to_pid, "A")
  end

  @spec get_neighbours(world_pid, room_pid) :: list(room_pid)
  def get_neighbours(world, room) do
    %{
      pid_to_label: pid_to_label,
      label_to_pid: label_to_pid,
      graph: graph
    } = _get_state(world)

    room_label = Map.get(pid_to_label, room)
    neighbours = []
    for edge <- :digraph.out_edges(graph, room_label) do
      {_,_,v2,_} = :digraph.edge(graph,edge)
      neighbour_pid = Map.get(label_to_pid, v2)
      [neighbour_pid | neighbours]
    end
    neighbours
  end

  @spec get_neighbours(world_pid, room_pid, atom) :: room_pid
  def get_neighbours(world, room, direction) do
    %{
      pid_to_label: pid_to_label,
      label_to_pid: label_to_pid,
      graph: graph
    } = _get_state(world)

    room_label = Map.get(pid_to_label, room)
    a = Enum.reduce(
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
  end

  # Private helper functions

  @spec _get_state(world_pid) :: State.t()
  defp _get_state(world) do
    Agent.get(world, & &1)
  end

  @spec _get_state(world_pid, key) :: state_attribute
  defp _get_state(world, key) do
    Agent.get(world, &Map.get(&1, key))
  end

  @spec _update_state(world_pid, key, state_attribute()) :: atom()
  defp _update_state(world, key, value) do
    Agent.update(world, &Map.put(&1, key, value))
  end

  @spec _update_state(world_pid, state_attribute()) :: atom()
  defp _update_state(world, state) do
    Agent.update(world, fn _ -> state end)
  end
end
