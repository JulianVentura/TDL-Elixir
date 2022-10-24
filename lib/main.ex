defmodule Main do
  require Entity

  entity = Entity.start_link(80, :rock)
  Entity.attack(entity,20,:paper)
  IO.inspect(Entity.get_state(entity))
end
