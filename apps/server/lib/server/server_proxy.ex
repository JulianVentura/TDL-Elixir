defmodule IServerProxy do
  def receive_state(server, state) do
    GenServer.cast(server, {:receive_state, state})
  end
end
