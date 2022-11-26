defmodule ProcessKiller do
  use GenServer
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: ProcessKiller)
  end

  def kill(killer, process_id) do
    GenServer.call(killer, {:kill, process_id})
  end
  
  def ping(killer) do
    GenServer.call(killer, :ping)
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end
  
  @impl true
  def handle_call({:kill, process_id}, _from, state) do
    process_id = IEx.Helpers.pid(process_id)
    Logger.info("ProcessKiller: Kill received, pid: #{inspect process_id}")
    result = Process.exit(process_id, :kill) 
    #send(process_id, :sarasa)
    #Logger.info("ProcessKiller: Kill-sent")
    Logger.info("ProcessKiller: Kill result #{result}")
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call(:ping, _from, state) do
    Logger.info("ProcessKiller: Ping received")
    {:reply, :ping, state}
  end
end
