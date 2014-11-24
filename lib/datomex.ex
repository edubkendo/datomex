defmodule Datomex do
  @moduledoc """
  Datomex is a low level driver for the Datomic database.

  Datomex utilizes Datomic's REST API, so in order to use Datomex,
  a Datomic peer to serve as an HTTP server must be running. The peer can be
  executed with the following:

      bin/rest -p port [-o origins]? [alias uri]+
  
  For example, to run Datomex's tests, start Datomic with:

      bin/rest -p 8888 -o /'*'/  db datomic:mem://

  More information about the REST API is available at http://docs.datomic.com/rest.html .

  Datomex must be initialized by calling `start_link` and passing in the `server`,
  `port`, `alias` and `name`.  For example:

      Datomex.start_link "localhost", 8888, "db", "test"

  * `server` - the host where Datomic is running, as a binary, example: `"localhost"`
  * `port` - the port where Datomic is running as an integer, example: `80`
  * `alias_db` - the name of the alias for the datomic uri, example: `"db"`
  * `name` - the name of the default database, example: `"test"`

  """

  @doc """
  Configures Datomex for connection with your Datomic Peer.

      Datomex.start_link "localhost", 8888, "db", "test"

  * `server` - the host where Datomic is running, as a binary, example: `"localhost"`
  * `port` - the port where Datomic is running as an integer, example: `80`
  * `alias_db` - the name of the alias for the datomic uri, example: `"db"`
  * `name` - the name of the default database, example: `"test"`  
  """
  def start_link(server, port, alias_db, name) do
    config = %Datomex.Config{ server: server, port: port, alias_db: alias_db, name: name }
    {:ok, _pid} = Agent.start_link(fn -> config end, name: :config)
  end

  @doc """
  Get a list of Datomic storages

    iex> Datomex.storages
    {:ok,
        %HTTPoison.Response{body: "[\"db\"]",
         headers: %{"Content-Length" => "6",
           "Content-Type" => "application/edn;charset=UTF-8",
           "Date" => "Mon, 24 Nov 2014 10:14:24 GMT",
           "Server" => "Jetty(8.1.11.v20130520)", "Vary" => "Accept"},
         status_code: 200}}

  """
  def storages do
    HTTPoison.get("#{root}data/")
  end

  @doc """
  Get a list of Datomic databases from the configured alias.
  """
  def databases do
    HTTPoison.get("#{root}data/#{alias_db}/")
  end

  @doc """
  Get a list of Datomic databases from a passed in alias.
  """
  def databases(alias_name) do
    HTTPoison.get("#{root}data/#{alias_name}/")
  end

  @doc """
  Create a new database at the configured alias.
  """
  def create_database(name) do
    params = %{"db-name": name}
             |> URI.encode_query
    HTTPoison.post("#{root}data/#{alias_db}/?" <> params, "")
  end

  @doc """
  Create a new database at the passed in alias.
  """
  def create_database(alias_name, name) do
    params = %{"db-name": name}
             |> URI.encode_query
    HTTPoison.post("#{root}data/#{alias_name}/?" <> params, "")
  end

  @doc """
  Send a transaction to Datomic.
  
      movies = ~s([
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
      ])
      Datomex.transact movies

  """
  def transact(data) do
    params = %{"tx-data": data}
      |> URI.encode_query
    HTTPoison.post("#{db_uri}?" <> params, "", %{"Accept-Header" => "application/edn"})
  end

  @doc """
  Get some datoms from Datomic by index.
  """
  def datoms(index) do
    params = %{"index": index}
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}datoms?#{params}"
  end

  @doc """
  Get some datoms from Datomic by index with optional arguments.
  """
  def datoms(index, opts) do
    params = %{index: index}
      |> Enum.into(opts)
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}datoms?#{params}"
  end

  @doc """
  Get a range of index data.
  """
  def index_range(index, attrid) do
    params = %{index: index, a: attrid}
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}datoms?#{params}"
  end
  
  def index_range(index, attrid, opts) do
    params = %{index: index, a: attrid}
      |> Enum.into(opts)
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}datoms?#{params}"
  end
  
  @doc """
  Get an entity from Datomic.
  """
  def entity(opts) when is_map(opts) do
    params = opts
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}entity?#{params}"
  end

  def entity(eid) do
    params = %{e: eid}
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}entity?#{params}"
  end
  
  def entity(eid, opts) do
    params = %{e: eid}
      |> Enum.into(opts)
      |> URI.encode_query
    HTTPoison.get "#{db_uri_}entity?#{params}"
  end

  @doc """
  Query datomic.
  
      Datomex.q(~s([:find ?m :where [?m :movie/title "trainspotting"]]))
  """
  def q(query) do
    params = %{q: query, args: "[{:db/alias \"#{db_alias}\"}]"}
      |> URI.encode_query
    HTTPoison.get "#{root}api/query?#{params}"
  end

  def q(query, opts) when is_map(opts) do
    params = %{q: query, args: "[{:db/alias \"#{db_alias}\"}]"}
      |> Enum.into(opts)
      |> URI.encode_query
    HTTPoison.get "#{root}api/query?#{params}"
  end

  def q(query, args) do
    params = %{q: query, args: args}
      |> URI.encode_query
    HTTPoison.get "#{root}api/query?#{params}"
  end

  def q(query, args, opts) do
    params = %{q: query, args: args}
      |> Enum.into(opts)
      |> URI.encode_query
    HTTPoison.get "#{root}api/query?#{params}"
  end

  # Helper functions
  defp get_config(elem) do
    Agent.get(:config, &Map.get(&1, elem))
  end

  defp root, do: "http://#{server}:#{port}/"
  defp db_alias, do: alias_db <> "/" <> name
  defp db_uri, do: "#{root}data/#{db_alias}/"
  defp db_uri_, do: db_uri <> "-/"
  defp server, do: get_config(:server)
  defp port, do: get_config(:port)
  defp alias_db, do: get_config(:alias_db)
  defp name, do: get_config(:name)
end
