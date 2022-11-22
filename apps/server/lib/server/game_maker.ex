defmodule GameMaker do
  use GenServer

  # Public API
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: GameMaker)
  end

  def new_game(maker, client) do
    GenServer.call(maker, {:new_game, client})
  end

  # Server API

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:new_game, client}, _from, worlds) do
      %{
        true => finished,
        false => not_finished,
      } = Enum.group_by(worlds, fn world -> World.finished?(world) end) 

      selected_world = 
        not_finished
          |> Enum.filter(fn world -> !World.full?(world) end)
          |> List.first([World.start_link])

      wrlds =
        not_finished
          |> Enum.concat(selected_world)
          |> Enum.uniq()

      cpid = ClientProxy.start_link(selected_world)
      finished |> __free_finished

      {:reply, {:ok, {node(), cpid}}, wrlds}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DB.Registry: #{msg}")
    {:noreply, state}
  end

  defp __free_finished(worlds) do
    %{
      true => finished,
      false => not_finished,
    } = Enum.group_by(worlds, fn world -> World.finished?(world) end) 

    Enum.map(finished, fn world -> World.stop(world) end)

    not_finished
  end
end
