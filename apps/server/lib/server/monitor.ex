defmodule Monitor do
  def create do
    %{}
  end

  def monitor(pid_to_ref, pid) do
    ref = Process.monitor(pid)
    pid_to_ref = Map.put(pid_to_ref, pid, ref)

    pid_to_ref
  end

  def demonitor(pid_to_ref, pid) do
    {ref, pid_to_ref} = Map.pop(pid_to_ref, pid)
    Process.demonitor(ref)

    pid_to_ref
  end
end
