defmodule ArbiterTest do


use ExUnit.Case
doctest Smokers.Arbiter


test "rand_key" do
    assert Smokers.Arbiter.rand_key(%{a: 1}) == :a
end


test "smokers_register" do
    state0 = Smokers.Arbiter.new_state([:t1, :t2])
    pid = self()
    state = Smokers.Arbiter.smokers_register(state0, :t1, pid)
    # TODO
end


end
