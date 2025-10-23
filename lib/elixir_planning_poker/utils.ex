defmodule ElixirPlanningPokerWeb.Utils do
  def atom_keys_to_strings(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      pair -> pair
    end)
  end

  def atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      key = if is_binary(k), do: String.to_atom(k), else: k

      value =
        cond do
          is_map(v) -> atomize_keys(v)
          is_list(v) -> Enum.map(v, &if(is_map(&1), do: atomize_keys(&1), else: &1))
          true -> v
        end

      {key, value}
    end
  end
end
