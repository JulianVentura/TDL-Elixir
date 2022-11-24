defmodule Monitor do
  def create do
    {%{}, %{}}
  end

  def monitor({pid_to_ref, ref_to_pid}, pid) do
    ref = Process.monitor(pid)
    pid_to_ref = Map.put(pid_to_ref, pid, ref)
    ref_to_pid = Map.put(ref_to_pid, ref, pid)

    {pid_to_ref, ref_to_pid}
  end

  def delete_by_ref({pid_to_ref, ref_to_pid}, ref) do
    {pid, ref_to_pid} = Map.pop(ref_to_pid, ref)

    {pid, {pid_to_ref, ref_to_pid}}
  end

  def demonitor({pid_to_ref, ref_to_pid}, pid) do
    {ref, pid_to_ref} = Map.pop(pid_to_ref, pid)
    ref_to_pid = Map.delete(ref_to_pid, ref)
    Process.demonitor(ref)

    {pid_to_ref, ref_to_pid}
  end
end
