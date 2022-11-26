defmodule IProcessKiller do
  def kill(process_id) do
    Node.connect(:"server@localhost")
    GenServer.call({ProcessKiller, :"server@localhost"}, {:kill, process_id})
  end
  def ping() do
    Node.connect(:"server@localhost")
    GenServer.call({ProcessKiller, :"server@localhost"}, :ping)
  end
end

process_id = 
  IO.gets("Ingrese PID: ") 
  |> String.trim 
IProcessKiller.kill(process_id)

#IO.inspect(Node.connect(:"server@localhost"))
#IO.inspect(Node.list)
#IProcessKiller.ping
