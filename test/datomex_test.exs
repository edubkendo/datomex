defmodule DatomexTest do
  use ExUnit.Case

  @movies """
[
  {:db/id #db/id[:db.part/db]
   :db/ident :movie/title
   :db/valueType :db.type/string
   :db/cardinality :db.cardinality/one
   :db/doc "movie's title"
   :db.install/_attribute :db.part/db}
  {:db/id #db/id[:db.part/db]
   :db/ident :movie/rating
   :db/valueType :db.type/double
   :db/cardinality :db.cardinality/one
   :db/doc "movie's rating"
   :db.install/_attribute :db.part/db}
]
"""

  setup do
    Datomex.start_link "localhost", 8888, "db", "test"
    :ok
  end

  test "fetches available storages" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.storages
    {:ok, {:vector, storage}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.any?(storage, fn(x) -> x == "db" end)
  end

  test "fetches a list of databases" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.databases
    {:ok, {:vector, databases}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "fetches a list of databases for a storage alias" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.databases("db")
    {:ok, {:vector, databases}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "creates a database" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.create_database("test")
    {:ok, {:vector, databases}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "creates a database with alias" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.create_database("db", "test")
    {:ok, {:vector, databases}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "makes transactions" do
     {:ok, %HTTPoison.Response{ body: body }} = Datomex.transact @movies
     {:ok, {:map, tx}} = :erldn.parse_str(String.to_char_list(body))
     assert Keyword.has_key? tx, :"db-after"
  end

  test "gets datoms" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.datoms "eavt"
    assert String.length(body) > 0
  end

  test "gets datoms with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.datoms("eavt", %{limit: 1})
    {:ok, {:vector, datoms}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.count(datoms) == 1
  end

  test "gets a range of index data" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.index_range("eavt", "db/ident")
    assert String.length(body) > 0
  end

  test "gets a range of index data with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.index_range("eavt", "db/ident", %{limit: 1})
    {:ok, {:vector, datoms}} = :erldn.parse_str(String.to_char_list(body))
    assert Enum.count(datoms) == 1
  end

  test "get an entity" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity 1
    {:ok, {:map, entity}} = :erldn.parse_str(String.to_char_list(body))
    assert Keyword.fetch(entity, :"db/id") == {:ok, 1}
  end

  test "get an entity with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity(%{e: 1, since: 0})
    {:ok, {:map, entity}} = :erldn.parse_str(String.to_char_list(body))
    assert Keyword.fetch(entity, :"db/id") == {:ok, 1}
  end

  test "get an entity with entity and options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity(%{e: 1, since: 0})
    {:ok, {:map, entity}} = :erldn.parse_str(String.to_char_list(body))
    assert Keyword.fetch(entity, :"db/id") == {:ok, 1}
  end

  test "query" do
    Datomex.transact(~s([[:db/add #db/id [:db.part/user] :movie/title "trainspotting"]]))
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q(~s([:find ?m :where [?m :movie/title "trainspotting"]]))
    {:ok, {:vector, movies}} = :erldn.parse_str(String.to_char_list(body)) 
    {:ok, [movie |t]} = Keyword.fetch(movies, :vector)
    assert movie > 1
  end

  test "query with options" do
    Datomex.transact("[[:db/add #db/id [:db.part/user] :movie/title \"the matrix\"]]")
    Datomex.transact("[[:db/add #db/id [:db.part/user] :movie/title \"the matrix reloaded\"]]")
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q("[:find ?m :where [?m :movie/title]]", %{ limit: 1, offset: 2 })
    {:ok, {:vector, movies}} = :erldn.parse_str(String.to_char_list(body)) 
    {:ok, [movie |t]} = Keyword.fetch(movies, :vector)
    assert movie > 1
  end

  test "query with args" do
    args = """
[
        ["Doe" "John" "jdoe@example.com"]
        ["jdoe@example.com" 71]
]
"""
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q("[:find ?first ?height :in [?last ?first ?email] [?email ?height]]", args)
    assert :erldn.parse_str(String.to_char_list(body)) == {:ok, {:vector, [vector: ["John", 71]]}}
  end
end
