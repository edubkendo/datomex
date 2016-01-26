Datomex
=======

Low level Elixir drivers for the [Datomic database](http://www.datomic.com/).

API Docs at: http://hexdocs.pm/datomex

## Install

Add Datomex and HTTPoison to your mix.exs dependencies:

```elixir
def deps do
[ {:datomex, "~> 0.0.1"},
  {:httpoison, "~> 0.8.0" } ]
end
```

## Usage

```elixir
Datomex.start_link "localhost", 8888, "db", "test"

Datomex.databases
# {:ok,
#   %HTTPoison.Response{body: "[\"test\"]",
#   headers: %{"Content-Length" => "8",
#   "Content-Type" => "application/edn;charset=UTF-8",
#   "Date" => "Sun, 23 Nov 2014 08:44:59 GMT",
#   "Server" => "Jetty(8.1.11.v20130520)", "Vary" => "Accept"},
#   status_code: 200}}

Datomex.create_database("test_02")
# {:ok,
#   %HTTPoison.Response{body: "[\"test\" \"test_02\"]",
#   headers: %{"Content-Length" => "18",
#     "Content-Type" => "application/edn;charset=UTF-8",
#     "Date" => "Sun, 23 Nov 2014 08:46:22 GMT",
#     "Server" => "Jetty(8.1.11.v20130520)", "Vary" => "Accept"},
#   status_code: 201}}

movies = """
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
Datomex.transact movies
# {:ok,
#   %HTTPoison.Response{body: "{:db-before {:basis-t 1119, :db/alias \"db/test\"}, :db-after {:basis-t 1120, :db/alias \"db/test\"}, :tx-data [{:e 13194139534432, :a 50, :v #inst \"2014-11-23T08:48:27.678-00:00\", :tx 13194139534432, :added true}], :tempids {-9223367638809264861 64, -9223367638809264860 63}}",
#   headers: %{"Content-Length" => "272",
#     "Content-Type" => "application/edn;charset=UTF-8",
#     "Date" => "Sun, 23 Nov 2014 08:48:27 GMT",
#     "Server" => "Jetty(8.1.11.v20130520)", "Vary" => "Accept"},
#   status_code: 201}}

Datomex.datoms "eavt"
# {:ok,
# %HTTPoison.Response{body: "[{:e 0, :a 10, :v :db.part/db, :tx 13194139533312, :added true}...

Datomex.entity 1
# {:ok,
#   %HTTPoison.Response{body: "{:db/ident :db/add, :db/doc \"Primitive assertion. All transactions eventually reduce to a collection of primitive assertions and retractions of facts, e.g. [:db/add fred :age 42].\", :db/id 1}",
#   headers: %{"Content-Length" => "191",
#     "Content-Type" => "application/edn;charset=UTF-8",
#     "Date" => "Sun, 23 Nov 2014 08:51:32 GMT",
#     "Server" => "Jetty(8.1.11.v20130520)", "Vary" => "Accept"},
#   status_code: 200}}

Datomex.transact(~s([[:db/add #db/id [:db.part/user] :movie/title "trainspotting"]]))
{:ok, %HTTPoison.Response{ body: body }} = Datomex.q(~s([:find ?m :where [?m :movie/title "trainspotting"]]))
movies = Exdn.to_elixir!(body)
# [vector: [17592186045486], vector: [17592186045538], vector: [17592186045481],
# vector: [17592186045483], vector: [17592186045478], vector: [17592186045509],
# vector: [17592186045474], vector: [17592186045468], vector: [17592186045503],
# vector: [17592186045466], vector: [17592186045472], vector: [17592186045499],
# vector: [17592186045530], vector: [17592186045493], vector: [17592186045490],
# vector: [17592186045524], vector: [17592186045521]]
```

## Related Projects

The [Exdn edn parser library](https://github.com/psfblair/exdn) 
([API docs](http://hexdocs.pm/exdn/2.1.1/api-reference.html)) may be used with
Datomex, both to parse incoming edn and to generate edn strings from Elixir data
structures. Some examples of how this can be done may be found in the tests.

## TODO
- Add docs
- Tighter integration with `exdn`.