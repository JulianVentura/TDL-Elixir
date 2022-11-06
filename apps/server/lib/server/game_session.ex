defmodule GameSession do
  use GenServer

  # Public API
  # TODO: Pasar el nombre del mapa
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def new_client(session, client) do
    GenServer.call(session, {:new_client, client})
  end

  # Server API
  @impl true
  def init(:ok) do
    {:ok, %{:clients => [], :first_room => nil, :started => false}}
    # Spawnear Rooms, crear mapa
  end

  @impl true
  def handle_call({:new_client, client}, _from, state) do
    # Fijarse si lo admite (si el juego comenzó)
    # Responder segun corresponda
    %{
      :clients => clients,
      :first_room => first_room,
      :started => started
    } = state
    
    if started do
      # Denegar acceso 
    end
  end

  # Flujo de sesión:
  #   - Sala de espera: 
  #     * GameSession spawnea a los procesos Room construyendo el mapa
  #     * Todos los jugadores bloqueados en GameSession
  #     * Se espera un tiempo hasta iniciar la partida 
  #     * Clientes pueden darle a continuar
  #   - Comienza el juego
  #     * GameSession le traspasa el control de los ClientProxy a la Room indicada

  # Estado interno:
  #   * Jugadores en la sesión
  #   * Rooms de la sesión 
  # 
  # Notas:
  #   * Crash de ClientProxy
  #   * Room inicia con enemigos random
  # 
  # Interfaz Room:
  #   * new_client(client)
end
