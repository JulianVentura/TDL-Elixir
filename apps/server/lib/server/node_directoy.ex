defmodule NodeDirectory do
  use GenServer
  require Logger

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: NodeDirectory)
  end

  def get_neighbors(pid) do
    GenServer.call(pid, :get_neighbors)
  end
  
  @impl true
  def init(:ok) do
    Logger.info("Starting NodeDirectory")
    Node.connect(:"server@localhost")
    :net_kernel.monitor_nodes(true)
    {:ok, []}
  end

  @impl true
  def handle_call(:get_neighbors, _from, neighbors) do
    {:reply, neighbors, neighbors}
  end
  
  @impl true
  def handle_info({:nodeup, new_node}, neighbors) do
    is_server_node = 
      new_node
        |> Atom.to_string
        |> String.starts_with?("server")  
  
    new_neighbors = 
      case is_server_node do
        true -> 
          Logger.info("New node in the system: #{new_node}")
          [new_node | neighbors]
        false -> neighbors
      end

    {:noreply, new_neighbors}
  end
  
  @impl true
  def handle_info({:nodedown, node_down}, neighbors) do
    new_neighbors = 
      case node_down in neighbors do
        true -> 
          Logger.info("Node #{node_down} left the system")
          List.delete(neighbors, node_down)
        false -> neighbors
      end

    {:noreply, new_neighbors}
  end
end
