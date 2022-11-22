defmodule ServerProxy do
  use GenServer

  # Client API

  def start_link(server_name) do
    GenServer.start_link(__MODULE__, server_name, name: CServerProxy)
  end

  def attack(pid, enemy) do
    GenServer.call(pid, {:attack, enemy})
  end

  def move(pid, direction) do
    GenServer.call(pid, {:move, direction})
  end

  def receive_state(pid, state) do
    GenServer.call(pid, {:receive_state, state})
  end

  # GenServer API

  @impl true
  def init(server_name) do
    {node_address, client_proxy_name} = IGameMaker.new_game({ GameMaker, server_name }) # TODO: ver
    
    Node.connect(node_address)

    client_proxy = {node_address, client_proxy_name}

    IClientProxy.hello_server(client_proxy, {node(), self()})  
    state = %{} # TODO: ver

    {:ok, {client_proxy, state}}
  end

  @impl true
  def handle_call({:attack, enemy}, _from, {client_proxy, state}) do
    # TODO: validar
    IClientProxy.attack(client_proxy, enemy)

    {:reply, :ok, {client_proxy, state}}
  end

  @impl true
  def handle_call({:move, direction}, _from, {client_proxy, state}) do
    # TODO: validar
    IClientProxy.move(client_proxy, direction)

    {:reply, direction, {client_proxy, state}}
  end

  @impl true
  def handle_cast({:receive_state, state}, {client_proxy}) do
    Drawer.draw(state, "", "") # TODO: ver

    {:noreply, {client_proxy, state}}
  end
end
