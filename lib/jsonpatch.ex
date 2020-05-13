defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.
  """

  alias Jsonpatch.FlatMap
  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  @doc """
  Apply a Jsonpatch to a map.
  """
  @spec apply_patch(Jsonpatch.Operation.t | list(Jsonpatch.Operation.t), map()) :: {map(), Jsonpatch.Operation.t | list(Jsonpatch.Operation.t)}
  def apply_patch(json_patch, target)

  def apply_patch(json_patch, %{} = target) when is_list(json_patch)  do
    Enum.reduce(json_patch, target, &apply_patch/2)
  end

  def apply_patch(%Jsonpatch.Operation.Add{} = json_patch, %{} = target)  do
    Jsonpatch.Operation.Add.apply_op(json_patch, target)
  end

  @doc """
  Creates a patch from the difference of a source map to a target map.

  ## Examples

      iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Elixir", "Sport", "Football"]}
      iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
      iex> Jsonpatch.diff(source, destination)
      {:ok, [
        %Jsonpatch.Operation.Add{path: "/age", value: 33},
        %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
        %Jsonpatch.Operation.Replace{path: "/married", value: true},
        %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
        %Jsonpatch.Operation.Remove{path: "/hobbies/2"}
      ]}
  """
  @spec diff(map, map) :: {:error, nil} | {:ok, list(Jsonpatch.Operation.t)}
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    source = FlatMap.parse(source)
    destination = FlatMap.parse(destination)

    {:ok, []}
    |> additions(source, destination)
    |> replaces(source, destination)
    |> removes(source, destination)
  end

  def diff(_source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "add"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_additions(list(Jsonpatch.Operation.t), map, map) :: {:error, nil} | {:ok, list(Jsonpatch.Operation.t)}
  def create_additions(accumulator \\ [], source, destination)

  def create_additions(accumulator, %{} = source, %{} = destination) do
    additions =
      Map.keys(destination)
      |> Enum.filter(fn key -> not Map.has_key?(source, key) end)
      |> Enum.map(fn key -> %Add{path: key, value: Map.get(destination, key)} end)

    {:ok, accumulator ++ additions}
  end

  @doc """
  Creates "remove"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_removes(list(Jsonpatch.Operation.t), map, map) :: {:error, nil} | {:ok, list(Jsonpatch.Operation.t)}
  def create_removes(accumulator \\ [], source, destination)

  def create_removes(accumulator, %{} = source, %{} = destination) do
    removes =
      Map.keys(source)
      |> Enum.filter(fn key -> not Map.has_key?(destination, key) end)
      |> Enum.map(fn key -> %Remove{path: key} end)

    {:ok, accumulator ++ removes}
  end

  @doc """
  Creates "replace"-operations by comparing keys and values of source and destination. The source and
  destination map have to be flat maps.
  """
  @spec create_replaces(list(Jsonpatch.Operation.t), map, map) :: {:error, nil} | {:ok, list(Jsonpatch.Operation.t)}
  def create_replaces(accumulator \\ [], source, destination)

  def create_replaces(accumulator, source, destination) do
    replaces =
      Map.keys(destination)
      |> Enum.filter(fn key -> Map.has_key?(source, key) end)
      |> Enum.filter(fn key -> Map.get(source, key) != Map.get(destination, key) end)
      |> Enum.map(fn key -> %Replace{path: key, value: Map.get(destination, key)} end)

    {:ok, accumulator ++ replaces}
  end

  # ===== ===== PRIVATE ===== =====

  defp additions({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_additions(accumulator, source, destination)
  end

  defp removes({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_removes(accumulator, source, destination)
  end

  defp replaces({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_replaces(accumulator, source, destination)
  end
end
