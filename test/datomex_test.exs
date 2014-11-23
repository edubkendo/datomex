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
end
