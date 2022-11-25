defmodule IServerProxy do
  def receive_state(server, state) do
    GenServer.cast(server, {:receive_state, state})
  end

  def disconnect(server, reason) do
    GenServer.cast(server, {:disconnect, reason})
  end
end
