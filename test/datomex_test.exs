defmodule DatomexTest do
  use ExUnit.Case

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
end
