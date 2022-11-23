defmodule ClientProxyMock do
  def start_link() do
    {_, client} = GenServer.start_link(__MODULE__, %{})
    client
  end

  @impl true
  def handle_cast({:receive_state, recv_state}, state) do
    {:noreply, %{}}
  end
end
