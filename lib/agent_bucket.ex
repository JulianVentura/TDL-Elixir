defmodule AgentBucket do
  use Agent

  @doc """
  Starts a new bucket.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{:agent => [], :value => 0} end)
  end

  def getAgents(bucket) do
    Agent.get(bucket, &Map.get(&1, :agent))
  end

  def addAgent(bucket, agent) do
    agents = Agent.get(bucket, &Map.get(&1, :agent))
    Agent.update(bucket, &Map.put(&1, :agent, agents ++ [agent]))
  end

  def updateValue(bucket, value) do
    Agent.update(bucket, fn dict ->
      Map.put(dict, :value, value)
    end)
  end

  def getValue(bucket) do
    Agent.get(bucket, &Map.get(&1, :value))
  end

  def sendValue(bucket, value) do
    agents = AgentBucket.getAgents(bucket)

    if length(agents) > 0 do
      AgentBucket.sendValueAndUpdate(hd(agents), value, bucket)
    end
  end

  def sendValueAndUpdate(bucket, value, returnBucket) do
    agents = AgentBucket.getAgents(bucket)

    if length(agents) > 0 do
      AgentBucket.sendValueAndUpdate(hd(agents), value, bucket)
      value = AgentBucket.getValue(bucket)
      AgentBucket.updateValue(returnBucket, value * 2)
    else
      AgentBucket.updateValue(returnBucket, value * 2)
    end
  end
end
