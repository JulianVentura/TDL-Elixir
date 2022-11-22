defmodule ServerProxy do
  use GenServer

  # Client API

  def start_link(server_name) do
    GenServer.start_link(__MODULE__, server_name, name: CServerProxy)
  end

  def attack(pid, enemy) do
    GenServer.call(pid, {:attack, enemy})
  end

  def move(pid, room) do
    GenServer.call(pid, {:move, room})
  end

  def receive_state(pid, state) do
    GenServer.call(pid, {:receive_state, state})
  end

  # GenServer API

  @impl true
  def init(server_name) do
    {node_address, client_proxy_name} = IGameMaker.new_game({ GameMaker, server_name }) # TODO: ver

    if Node.connect(node_address) do
      client_proxy = {node_address, client_proxy_name}
      IClientProxy.hello_server(client_proxy, {node(), self()})
      # TODO: creo que puede romper con el estado vacío en los handle_call attack y move
      state = %{}

      {:ok, {client_proxy, state}}
    else
      reason = """
        No se pudo conectar al ClientProxy.
        node_address: #{node_address}
        client_proxy_name:#{client_proxy_name}
      """

      {:stop, reason}
    end
  end

  @impl true
  def handle_call({:attack, enemy}, _from, {client_proxy, state}) do
    enemy_exists = Enum.any?(state[:enemies], fn(e) -> e.id == enemy.id end)

    if enemy_exists do
      Drawer.draw(state, {"command", "Atacaste a #{enemy}"})
      IClientProxy.attack(client_proxy, enemy)
      {:reply, :ok, {client_proxy, state}}
    else
      Drawer.draw(state, {"err", "Enemigo inválido"})
      {:reply, :error, {client_proxy, state}}
    end
  end

  @impl true
  def handle_call({:move, room}, _from, {client_proxy, state}) do
    if room in state[:rooms] do
      Drawer.draw(state, {"command", "Te moviste a #{room}"})
      IClientProxy.move(client_proxy, room)
      {:reply, :ok, {client_proxy, state}}
    else
      Drawer.draw(state, {"err", "Habitación inexistente"})
      {:reply, :error, {client_proxy, state}}
    end

    {:reply, room, {client_proxy, state}}
  end

  @impl true
  def handle_cast({:receive_state, state}, {client_proxy}) do
    Drawer.draw(state, nil)

    {:noreply, {client_proxy, state}}
  end
end
