defmodule ServerProxy do
  use GenServer
  require Logger

  # Client API

  def start_link(server_name) do
    GenServer.start_link(__MODULE__, server_name, name: ServerProxy)
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
    Logger.info("Connecting to GameMaker on #{inspect server_name}")
    {client_proxy_name, node_address} = IGameMaker.new_game({ GameMaker, server_name }, {ServerProxy, node()}) # TODO: ver
    Logger.info(Node.connect(node_address))

    if Node.connect(node_address) do
      Logger.info("Connecting to ClientProxy on #{inspect node_address}")
      client_proxy = {client_proxy_name, node_address}
      Logger.info("Connection established")

      # TODO: creo que puede romper con el estado vacío en los handle_call attack y move
      state = %{}

      {:ok, {client_proxy, state}}
    else
      reason = """
        No se pudo conectar al ClientProxy.
        node_address: #{inspect node_address}
        client_proxy_name:#{inspect client_proxy_name}
      """
      Logger.error(reason)

      {:stop, reason}
    end
  end

  @impl true
  def handle_call({:attack, enemy}, _from, {client_proxy, state}) do
    enemy_exists = Enum.any?(state[:enemies], fn(e) -> e.id == enemy end)

    if enemy_exists do
      Drawer.draw(state, {"command", "Atacaste a #{ inspect enemy}"})
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
      Drawer.draw(state, {"command", "Te moviste a #{inspect room}"})
      IClientProxy.move(client_proxy, room)
      {:reply, :ok, {client_proxy, state}}
    else
      Drawer.draw(state, {"err", "Habitación inexistente"})
      {:reply, :error, {client_proxy, state}}
    end

    {:reply, room, {client_proxy, state}}
  end

  @impl true
  def handle_cast({:receive_state, received_state}, {client_proxy, _}) do
    Logger.info("Receive state")
    Logger.info(inspect received_state)
    Drawer.draw(received_state, nil)

    {:noreply, {client_proxy, received_state}}
  end
end
