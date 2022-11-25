defmodule Dmg do
  def get_stances() do
    [:fire, :water, :plant]
  end

  def get_multiplier(stance, other_stance) do
    other_stance_vec = case other_stance do
      :fire -> [1,0,0]
      :water -> [0,1,0]
      :plant -> [0,0,1]
    end
    stance_vec = case stance do
      :fire -> [1.0,2.0,0.5]
      :water -> [0.5,1.0,2.0]
      :plant -> [2.0,0.5,1.0]
    end
    ExtraMath.dot_product(stance_vec, other_stance_vec)
  end
end
