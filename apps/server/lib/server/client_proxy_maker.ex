defmodule ClientProxyMaker do
  use GenServer 
  require Logger
  
  # Public API
  def start_link(number) do
    Logger.info("Starting ClientProxyMaker")
    GenServer.start_link(__MODULE__, number, name: ClientProxyMaker)
  end

  def new(service, world, cli_address) do
    GenServer.call(service, {:new, world, cli_address})
  end

  def full?(service) do
    GenServer.call(service, :full?)
  end

  # Server API

  @impl true
  def init(number) do
    names = create(number)
    
    {:ok, {names, %{}}}
  end
  
  @impl true
  def handle_call(:full?, _from, state) do
    {free_names, _} = state
    result = Enum.empty?(free_names)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:new, world, cli_address}, _from, {[name | t], ref_to_name}) do
    child_specs = %{
      id: ClientProxy,
      start: {ClientProxy, :start_link, [Atom.to_string(name), world, cli_address]},
      restart: :temporary,
      type: :worker
    }
    
    {:ok, cpid} = DynamicSupervisor.start_child(ClientProxySupervisor, child_specs)

    Process.register(cpid, name)
    ref = Process.monitor(cpid)
    ref_to_name = Map.put(ref_to_name, ref, name)
     
    {:reply, {:ok, name}, {t, ref_to_name}}
  end
   
  @impl true
  def handle_info({:DOWN, ref, _, _, _}, {free_names, ref_to_name}) do
    {name, ref_to_name} = Map.pop(ref_to_name, ref)
    free_names = [name | free_names]

    {:noreply, {free_names, ref_to_name}}
  end

  defp create(number) do
    (1..number) 
      |> Enum.map(fn i -> String.to_atom("Jugador#{i}") end)
  end
end
