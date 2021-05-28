defmodule Smokers.Arbiter do


@compile if Mix.env == :test, do: :export_all


use GenServer
require Logger
require Record


defmodule State do
    defstruct [smokers: nil]
end

defmodule SmokerState do
    defstruct [smoker_pid: nil, amount: 0]
end


### API

def start_link(types) do
    GenServer.start_link(__MODULE__, types, [name: __MODULE__])
end


def register_smoker(arbiter_pid, type, smoker_pid) do
    GenServer.cast(arbiter_pid, {:register_smoker, type, smoker_pid})
end


def claim(arbiter_pid, type, smoker_pid) do
    GenServer.cast(arbiter_pid, {:claim, type})
end


### Callbacks

@impl true
def init(types) do
    state = new_state(types)
    Logger.info("Starting arbiter: state=#{inspect(state)} self=#{inspect(self())}")
    {:ok, state}
end


@impl true
def handle_call({:claim, type}, _from, state) do
    case try_claim(state.smokers, type) do
        {true, new_smokers} ->
            {:reply, :claim_ok, %State{smokers: new_smokers}}
        false ->
            {:reply, :claim_fail, state}
    end
end


@impl true
def handle_cast({:register_smoker, type, smoker_pid}, state) do
    new_state = smokers_register(state, type, smoker_pid)
    Logger.info("Arbiter - registering smoker: old_state=#{inspect(state)} new_state=#{inspect(new_state)}")
    Smokers.Smoker.registered(smoker_pid)
    Logger.info("Arbiter: all? #{inspect(all_smokers_registered(new_state))}")
    case all_smokers_registered(new_state) do
        true -> schedule_smoke()
        _ -> :ok
    end
    {:noreply, new_state}
end


@impl true
def handle_info(:put, state) do
    Logger.info("Arbiter: PUT_SMOKE: state=#{inspect state}")
    state = %State{state | smokers: rand_gen_type_and_bump_other_amounts(state.smokers)}
    Logger.info("Arbiter: PUT_SMOKE: new_state=#{inspect state}")
    schedule_smoke()
    {:noreply, state}
end


### Implementation

defp new_state(types) do
    smokers = for t <- types, into: %{}, do: {t, %SmokerState{}}
    %State{smokers: smokers}
end


defp smokers_register(state, type, pid) do
    smokers = state.smokers
    smoker_state = smokers[type]
    smokers = %{smokers | type => %SmokerState{smoker_state | smoker_pid: pid}}
    %State{state | smokers: smokers}
end


defp all_smokers_registered(state) do
    state.smokers |> Enum.all?(fn {_,smoker_state} -> smoker_registered(smoker_state) end)
end


defp smoker_registered(%SmokerState{smoker_pid: pid}) when is_pid(pid), do: true
defp smoker_registered(%SmokerState{smoker_pid: nil}), do: false


defp schedule_smoke() do
    ms = :rand.uniform(5000)
    :timer.send_after(ms, :put)
end


defp rand_key(map) do
    {key, _} = Enum.random(map)
    key
end


defp rand_gen_type_and_bump_other_amounts(smokers) do
    bump_other_amounts(smokers, rand_key(smokers))
end


defp bump_other_amounts(smokers, type) do
    Logger.info("Arbiter: bumping amounts: old=#{inspect smokers}")
    Logger.info("Arbiter: bumping amounts: type=#{type}")
    bump_amount = fn
        ({^type,_}, acc) -> acc # remain unchanged
        ({t, %SmokerState{amount: a} = sr}, acc) ->
            %{acc | t => %SmokerState{sr | amount: a+1}}
    end
    new_smokers = Enum.reduce(smokers, smokers, bump_amount)
    Logger.info("Arbiter: bumping amounts: new=#{inspect new_smokers}")
    new_smokers
end


defp try_claim(%{} = smokers, type) do
    dec_amount = fn
        (_, false) ->
            false # had failure earlier
        ({^type,_}, a) ->
            a # not changing for this type
        ({t, %SmokerState{amount: amount} = sr}, {true,acc}) when amount > 0 ->
            acc = %{acc | t => %SmokerState{sr | amount: amount-1}}
            {true, acc}
        ({_, %SmokerState{amount: amount}}, {true,_}) when amount <= 0 ->
            false
    end
    Enum.reduce(smokers, {true,smokers}, dec_amount)
end


end

