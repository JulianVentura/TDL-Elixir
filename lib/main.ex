defmodule Main do
  require TCPServer
  {:ok, principalAgent} = AgentBucket.start_link([])
  {:ok, secondaryAgent1} = AgentBucket.start_link([])
  {:ok, secondaryAgent2} = AgentBucket.start_link([])

  AgentBucket.addAgent(principalAgent, secondaryAgent1)
  AgentBucket.addAgent(secondaryAgent1, secondaryAgent2)

  TCPServer.accept(4040, principalAgent)
end
