defmodule SmokersTest do
  use ExUnit.Case
  doctest Smokers

  test "greets the world" do
    assert Smokers.hello() == :world
  end
end
