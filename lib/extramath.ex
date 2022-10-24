defmodule ExtraMath do
  def dot_product(v, w) do
    Enum.reduce(Enum.zip(v, w), 0, fn e, acc -> acc + Tuple.product(e) end)
  end
end
