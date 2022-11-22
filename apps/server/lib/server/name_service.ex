defmodule NameService do
  use GenServer 
  require Logger
  
  # Public API
  def start_link(number, len) do
    Logger.info("Starting NameService")
    GenServer.start_link(__MODULE__, {number, len}, name: NameService)
  end

  def register_process(service, process) do
    GenServer.call(service, {:register_process, process})
  end

  def full?(service) do
    GenServer.call(service, :full?)
  end

  # Server API

  @impl true
  def init({number, len}) do
    names = create(number, len)
    
    {:ok, {names, %{}}}
  end
  
  @impl true
  def handle_call(:full?, _from, state) do
    {free_names, _} = state
    result = Enum.empty?(free_names)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:register_process, process}, _from, state) do
    {result, new_state} = register(state, process) 

    {:reply, result, new_state}
  end
   
  @impl true
  def handle_info({:DOWN, ref, _, _, _}, {free_names, ref_to_name}) do
    {name, ref_to_name} = Map.pop(ref_to_name, ref)
    free_names = [name | free_names]

    {:noreply, {free_names, ref_to_name}}
  end

  defp create(number, len) do
    (1..number) 
      |> Enum.map(fn _ -> create_name(len) end)
  end
  
  defp create_name(len) do
    (1..len) 
      |> Enum.map(fn _ -> Enum.random(?a..?z) end)
      |> List.to_string
      |> String.to_atom
  end

  defp register({[name | t], ref_to_name}, process) do
    Process.register(process, name)
    ref = Process.monitor(process)
    ref_to_name = Map.put(ref_to_name, ref, name)
     
    {{:ok, name}, {t, ref_to_name}}
  end

  defp register({[], ref_to_name}, _) do
    {:error, {[], ref_to_name}}
  end
end
