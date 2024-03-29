defmodule MongoDB do
  defrecord Collection, pid: nil, db: nil, name: nil

  @connections :mongodb_connections

  def connect(name, host, port, options // []) do
    check_table
    {:ok, pid} = :mongo_connection.start_link({host, port}, options)
    set_connection name, pid
    :ok
  end
  defp check_table do
    if :ets.info(@connections) == :undefined do
      :ets.new(@connections, [:set, :named_table, { :read_concurrency, true }])
    end
  end
  defp set_connection(name, pid) do
    :ets.insert(@connections, {name, pid})
  end

  def get_collection(connection_name, db, name) do 
    {:ok, Collection.new pid: get_connection(connection_name), db: db, name: name}
  end
  defp get_connection(name) do
    [{_,connection}] = :ets.lookup(@connections, name)
    connection
  end

  def insert(collection, docs = [h | _]) when is_list(h) do
    exec collection, fn -> do_insert(collection, docs) end
  end
  def insert(collection, doc) when is_record(doc), do: insert(collection, [doc.to_keywords])
  def insert(collection, doc = [{_,_}|_]), do: insert(collection, [doc])
  def insert(collection, docs) do
    insert collection, Enum.map(docs, fn(x) -> x.to_keywords end)
  end
  defp do_insert(collection, docs) do
    docs 
    |> to_tuples 
    |> mongo_insert(collection.name) 
    |> to_keywords
  end
  defp mongo_insert(docs, name), do: :mongo.insert(name, docs)

  def find(collection, query // {}) do
    exec collection, fn -> do_find(collection, query) end
  end
  defp do_find(collection, query) do
    query 
    |> to_tuple 
    |> mongo_find(collection.name) 
    |> :mongo_cursor.rest 
    |> to_keywords
  end
  defp mongo_find(q, name), do: :mongo.find(name, q)

  def delete(collection, query // {}) do
    exec collection, fn -> do_delete(collection, query) end
  end
  defp do_delete(collection, query) do
    query 
    |> to_tuple 
    |> mongo_delete(collection.name)
  end
  defp mongo_delete(q, name), do: :mongo.delete(name, q)

  defp exec(collection, to_do) do
    :mongo.do :unsafe, :master, collection.pid, collection.db, to_do
  end

  defp to_keywords(l), do: Enum.map(l, to_keyword(&1))
  defp to_keyword(tuple), do: tuple |> tuple_to_list |> to_keyword([])
  defp to_keyword([], acc), do: acc
  defp to_keyword([k, v | tail], acc), do: to_keyword(tail, [{k, v} | acc])

  defp to_tuples(l), do: Enum.map(l, to_tuple(&1))
  defp to_tuple(t) when is_tuple(t), do: t
  defp to_tuple(l) when is_list(l) do 
    l |> Enum.map(tuple_to_list(&1)) |> List.flatten |> list_to_tuple
  end
end
