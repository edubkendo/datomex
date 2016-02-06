defmodule DatomexTest do
  use ExUnit.Case

  def movies, do: [
    %{"db/id": dbid(:"db.part/db"),
      "db/ident": :"movie/title",
      "db/valueType": :"db.type/string",
      "db/cardinality": :"db.cardinality/one",
      "db/doc": "movie's title",
      "db.install/_attribute": :"db.part/db"},
    %{"db/id": dbid(:"db.part/db"),
      "db/ident": :"movie/rating",
      "db/valueType": :"db.type/double",
      "db/cardinality": :"db.cardinality/one",
      "db/doc": "movie's rating",
      "db.install/_attribute": :"db.part/db"}
    ] |> Exdn.from_elixir!

  setup do
    Datomex.start_link "localhost", 8888, "db", "test"
    :ok
  end

  test "fetches available storages" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.storages
    storage = Exdn.to_elixir!(body)
    assert Enum.any?(storage, fn(x) -> x == "db" end)
  end

  test "fetches a list of databases" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.databases
    databases = Exdn.to_elixir!(body)
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "fetches a list of databases for a storage alias" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.databases("db")
    databases = Exdn.to_elixir!(body)
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "creates a database" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.create_database("test")
    databases = Exdn.to_elixir!(body)
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "creates a database with alias" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.create_database("db", "test")
    databases = Exdn.to_elixir!(body)
    assert Enum.any?(databases, fn(x) -> x == "test" end)
  end

  test "makes transactions" do
     {:ok, %HTTPoison.Response{ body: body }} = Datomex.transact movies
     tx = Exdn.to_elixir!(body)
     assert Map.has_key? tx, :"db-after"
  end

  test "gets datoms" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.datoms "eavt"
    assert String.length(body) > 0
  end

  test "gets datoms with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.datoms("eavt", %{limit: 1})
    datoms = Exdn.to_elixir!(body)
    assert Enum.count(datoms) == 1
  end

  test "gets a range of index data" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.index_range("eavt", "db/ident")
    assert String.length(body) > 0
  end

  test "gets a range of index data with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.index_range("eavt", "db/ident", %{limit: 1})
    datoms = Exdn.to_elixir!(body)
    assert Enum.count(datoms) == 1
  end

  test "get an entity" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity 1
    entity = Exdn.to_elixir!(body)
    assert entity[:"db/id"] == 1
  end

  test "get an entity with options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity(%{e: 1, since: 0})
    entity = Exdn.to_elixir!(body)
    assert entity[:"db/id"] == 1
  end

  test "get an entity with entity and options" do
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.entity(%{e: 1, since: 0})
    entity = Exdn.to_elixir!(body)
    assert entity[:"db/id"] == 1
  end

  test "query" do
    insert = [[:"db/add", dbid(:"db.part/user"), :"movie/title", "trainspotting"]
             ] |> Exdn.from_elixir!
    Datomex.transact(insert)

    query = [:find, (q? :m),
             :where, [(q? :m), :"movie/title", "trainspotting"]
            ] |> Exdn.from_elixir!

    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q(query)
    [[movie] |_t] = Exdn.to_elixir!(body)
    assert movie > 1
  end

  test "query with options" do
    insert1 = [[:"db/add", dbid(:"db.part/user"), :"movie/title", "the matrix"]
              ] |> Exdn.from_elixir!
    Datomex.transact(insert1)

    insert2 = [[:"db/add", dbid(:"db.part/user"), :"movie/title", "the matrix reloaded"]
              ] |> Exdn.from_elixir!
    Datomex.transact(insert2)

    query = [:find, (q? :m), :where, [(q? :m), :"movie/title"]] |> Exdn.from_elixir!
    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q(query, %{ limit: 1, offset: 2 })

    [[movie] |_t] = Exdn.to_elixir!(body)
    assert movie > 1
  end

  test "query with args" do
    query = [:find, (q? :first), (q? :height),
             :in, [(q? :last), (q? :first), (q? :email)],
             [(q? :email), (q? :height)]] |> Exdn.from_elixir!

    args = [ ["Doe", "John", "jdoe@example.com"],
             ["jdoe@example.com", 71] ] |> Exdn.from_elixir!

    {:ok, %HTTPoison.Response{ body: body }} = Datomex.q(query, args)
    assert Exdn.to_elixir!(body) == [["John", 71]]
  end

  def q?(name_atom) do
    variable_symbol = name_atom |> to_string
    with_question_mark = "?" <> variable_symbol |> String.to_atom
    {:symbol, with_question_mark }
  end

  def dbid(db_part) do
    {:tag, :"db/id", [db_part]}
  end
end
