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
end
