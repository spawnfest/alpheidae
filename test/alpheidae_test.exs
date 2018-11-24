defmodule AlpheidaeTest do
  use ExUnit.Case
  doctest Alpheidae

  test "greets the world" do
    assert Alpheidae.hello() == :world
  end
end
