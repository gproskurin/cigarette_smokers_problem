defmodule ArbiterTest do


use ExUnit.Case
doctest Smokers.Arbiter

alias Smokers.Arbiter, as: A


test "rand_key" do
    assert A.rand_key(%{a: 1}) == :a
end


test "smokers_register" do
    state0 = A.new_state([:t1, :t2])
    pid = self()
    _state = A.smokers_register(state0, :t1, pid)
    # TODO
end


test "test claim_ok" do
    pid = self()
    smokers = %{
        t1: %A.SmokerState{smoker_pid: pid, amount: 0},
        t2: %A.SmokerState{smoker_pid: pid, amount: 5}
    }
    assert false == A.try_claim(smokers, :t2)
    {true, new_smokers} = A.try_claim(smokers, :t1)
    assert is_map(new_smokers)
end


test "test claim_fail" do
end


end
