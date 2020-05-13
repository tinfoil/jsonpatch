defmodule Jsonpatch.Operation do
  @moduledoc """
  Defines behaviour for apply a patch to a struct.
  """

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type t :: Add.t() | Remove.t() | Replace.t()

  @callback apply_op(Jsonpatch.Operation.t, map()) :: map()

  @doc """
  Uses a JSON patch path to get the last map that this path references.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.Operation.get_final_destination!(target, path)
      {%{"d" => 1}, "d"}
  """
  @spec get_final_destination!(map, binary) :: {map, binary}
  def get_final_destination!(target, path) when is_bitstring(path) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    find_final_destination(target, fragments)
  end

  @doc """
  Updatest a map reference by a given JSON patch path with the new final destination.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.Operation.update_final_destination!(target, %{"e" => 1}, path)
      %{"a" => %{"b" => %{"c" => %{"e" => 1}}}}
  """
  @spec update_final_destination!(map, map, binary) :: map
  def update_final_destination!(target, new_destination, path) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_update_final_destination(target, new_destination, fragments)
  end

  # ===== ===== PRIVATE ===== =====

  defp find_final_destination(%{} = target, [fragment | []]) do
    {target, fragment}
  end

  defp find_final_destination(%{} = target, [fragment | tail]) do
    Map.get(target, fragment)
    |> find_final_destination(tail)
  end

  # " [final_dest | [_last_ele |[]]] " means: We want to stop, when there are only two elements left.
  defp do_update_final_destination(%{} = target, new_final_dest, [final_dest | [_last_ele |[]]]) do
    Map.replace!(target, final_dest, new_final_dest)
  end

  defp do_update_final_destination(%{} = target, new_final_dest, [fragment | tail]) do
    Map.update!(target, fragment, &do_update_final_destination(&1 , new_final_dest, tail))
  end
end
