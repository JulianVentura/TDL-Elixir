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
    response = IGameMaker.new_game({GameMaker, server_name}, {ServerProxy, node()})

    {client_proxy_name, node_address} =
      case response do
        {:ok, v} -> v
        :error -> finish("No se ha podido iniciar una sesión")
      end

    if Node.connect(node_address) do
      Logger.info("Connecting to ClientProxy on #{node_address}")
      client_proxy = {client_proxy_name, node_address}
      Logger.info("Connection established")

      state = %{
        players: [],
        enemies: []
      }

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
      Drawer.draw(state)
      IClientProxy.attack(client_proxy, enemy)
      # TODO: Ver si se puede estos error de clientproxy
      {:reply, :ok, {client_proxy, state}}
    else
      Drawer.draw_msg("Enemigo inválido")
      {:reply, :error, {client_proxy, state}}
    end
  end

  @impl true
  def handle_call({:move, room}, _from, {client_proxy, state}) do
    if room in state[:rooms] do
      Drawer.draw(state)
      IClientProxy.move(client_proxy, room)
      # TODO: Ver si se puede estos error de clientproxy
      {:reply, :ok, {client_proxy, state}}
    else
      Drawer.draw_msg("Destino inexistente")
      {:reply, :error, {client_proxy, state}}
    end

    {:reply, room, {client_proxy, state}}
  end

  @impl true
  def handle_cast({:receive_state, received_state}, {client_proxy, _}) do
    Drawer.draw(received_state)

    {:noreply, {client_proxy, received_state}}
  end

  @impl true
  def handle_cast({:disconnect, reason}, {client_proxy, state}) do
    msg =
      case reason do
        :win -> "V I C T O R I A\nEl elixir de la vida brilla en tus manos!"
        :lose -> "D E R R O T A\nTal vez lo logres en tu próxima vida..."
        :internal_error -> "Error: Ha ocurrido un error interno"
        :server_disconnected -> "Error: Server disconnected"
        _ -> "Error: Unknown"
      end

    finish(msg)
    {:noreply, {client_proxy, state}}
  end

  defp finish(msg) do
    Drawer.draw_msg(msg)
    System.stop(0)
  end
end
