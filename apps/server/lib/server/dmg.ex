defmodule Dmg do
  def get_multiplier(stance, other_stance) do
    other_stance_vec = case other_stance do
      :rock -> [1,0,0]
      :paper -> [0,1,0]
      :scissors -> [0,0,1]
    end
    stance_vec = case stance do
      :rock -> [1.0,2.0,0.5]
      :paper -> [0.5,1.0,2.0]
      :scissors -> [2.0,0.5,1.0]
    end
    ExtraMath.dot_product(stance_vec, other_stance_vec)
  end
end
