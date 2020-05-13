defmodule Jsonpatch.Operation.Replace do
  @behaviour Jsonpatch.Operation

  @enforce_keys [:path, :value]
  defstruct [:path, :value]

  @doc """
  Applies an replace operation to a struct/map.

  ## Examples

      iex> add = %Jsonpatch.Operation.Replace{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"b" => 2}}
      iex> Jsonpatch.Operation.Replace.apply_op(add, target)
      %{"a" => %{"b" => 1}}
  """
  @impl true
  @spec apply_op(Jsonpatch.Operation.Replace.t(), map) :: map
  def apply_op(%Jsonpatch.Operation.Replace{path: path, value: value}, %{} = target) do
    {final_destination, last_fragment} = Jsonpatch.Operation.get_final_destination!(target, path)
    updated_final_destination = Map.replace!(final_destination, last_fragment, value)
    Jsonpatch.Operation.update_final_destination!(target, updated_final_destination, path)
  end
end
