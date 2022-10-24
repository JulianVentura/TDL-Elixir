defmodule TCPServer do
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port, agent) do
    {:ok, socket} =
      :gen_tcp.listen(
        port,
        [:binary, packet: :line, active: false, reuseaddr: true]
      )

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket, agent)
  end

  defp loop_acceptor(socket, agent) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.start_link(fn -> serve(client, agent) end)
    loop_acceptor(socket, agent)
  end

  defp serve(socket, agent) do
    # write_line(read_line(socket), socket)
    line = read_line(socket)
    {number, _} = Integer.parse(String.slice(line, 0..-2))

    AgentBucket.sendValue(agent, number)
    number = AgentBucket.getValue(agent)

    write_line(Integer.to_string(number) <> "\n", socket)
    serve(socket, agent)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
