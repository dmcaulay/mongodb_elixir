Code.require_file "test_helper.exs", __DIR__

defmodule MongoDBTest do
  defrecord TestObject, name: nil, data: nil

  use ExUnit.Case

  setup do
    MongoDB.connect(:db, '127.0.0.1', 27017)
  end

  test "collection returned if successful connection" do
    {:ok, collection} = MongoDB.get_collection(:db, :test, :docs)
    assert is_pid(collection.pid)
    assert collection.db == :test
    assert collection.name == :docs 
  end

  test "saving an object in the db" do
    {:ok, collection} = MongoDB.get_collection(:db, :test, :docs)
    assert MongoDB.delete(collection) == :ok
    to_save = TestObject.new name: "test", data: "this is fun"
    [stored] = MongoDB.insert(collection, [to_save.to_keywords])
    record = TestObject.new stored
    assert record == to_save
    [stored] = MongoDB.find(collection, [name: "test"])
    assert stored[:name] == "test"
    assert stored[:data] == "this is fun"
    assert is_binary(elem stored[:_id], 0)
    record = TestObject.new stored
    assert record == to_save
  end

  test "sorting results" do
    {:ok, collection} = MongoDB.get_collection(:db, :test, :docs)
    assert MongoDB.delete(collection) == :ok
    to_save = TestObject.new name: "test", data: 2
    MongoDB.insert(collection, [to_save])
    to_save_2 = TestObject.new name: "not_test", data: 1
    MongoDB.insert(collection, to_save_2.to_keywords)
    to_save_3 = TestObject.new name: "test", data: 3
    MongoDB.insert(collection, to_save_3)
    to_save_4 = TestObject.new name: "not_test", data: -1
    MongoDB.insert(collection, to_save_4)
    results = MongoDB.find(collection, {:'$query', {}, :'$orderby', {:data, 1}})
    assert Enum.map(results, TestObject.new &1) == [to_save_4,to_save_2,to_save,to_save_3] 
  end
end
