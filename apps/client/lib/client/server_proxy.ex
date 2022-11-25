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

  def disconnect(pid, reason) do
    GenServer.call(pid, {:disconnect, reason})
  end

  # GenServer API

  @impl true
  def init(server_name) do
    Logger.info("Connecting to GameMaker on #{server_name}")
    # TODO: ver
    {client_proxy_name, node_address} =
      IGameMaker.new_game({GameMaker, server_name}, {ServerProxy, node()})

    if Node.connect(node_address) do
      Logger.info("Connecting to ClientProxy on #{node_address}")
      client_proxy = {client_proxy_name, node_address}
      Logger.info("Connection established")

      # TODO: creo que puede romper con el estado vacío en los handle_call attack y move
      state = %{}

      {:ok, {client_proxy, state}}
    else
      reason = """
        No se pudo conectar al ClientProxy.
        node_address: #{node_address}
        client_proxy_name:#{client_proxy_name}
      """

      Logger.error(reason)

      {:stop, reason}
    end
  end

  @impl true
  def handle_call({:attack, enemy}, _from, {client_proxy, state}) do
    enemy_exists = Enum.any?(state[:enemies], fn e -> e.id == enemy end)

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
  def handle_cast({:receive_state, received_state}, {client_proxy, _}) do
    # Logger.debug("Receive state")
    # Logger.debug(inspect received_state)
    Drawer.draw(received_state, nil)

    {:noreply, {client_proxy, received_state}}
  end

  @impl true
  def handle_cast({:disconnect, reason}, {client_proxy, state}) do
    msg = case reason do
      :win -> "V I C T O R I A\nEl elixir de la vida brilla en tus mano!"
      :lose -> "D E R R O T A\nTal vez lo logres en tu próxima vida"
      :internal_error -> "Error: Ha ocurrido un error interno"
      :server_disconnected -> "Error: Server disconnected"
      _ ->  "Error: Unknown"
    end
    Drawer.draw_msg(msg)
    
    {:noreply, {client_proxy, state}}
  end
end
