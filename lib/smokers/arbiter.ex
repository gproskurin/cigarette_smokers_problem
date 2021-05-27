defmodule Smokers.Arbiter do


@compile if Mix.env == :test, do: :export_all


use GenServer
require Logger
require Record


Record.defrecordp(:rec_state, smokers: nil)
Record.defrecordp(:rec_smoker_state, smoker_pid: nil, amount: 0)


### API

def start_link(types) do
    GenServer.start_link(__MODULE__, types, [name: __MODULE__])
end


def register_smoker(arbiter_pid, type, smoker_pid) do
    GenServer.cast(arbiter_pid, {:register_smoker, type, smoker_pid})
end


### Callbacks

@impl true
def init(types) do
    state = new_state(types)
    Logger.info("Starting arbiter: state=#{inspect(state)} self=#{inspect(self())}")
    {:ok, state}
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
    smokers = rec_state(state, :smokers)
    smokers = rand_gen_type_and_bump_other_amounts(smokers)
    state = rec_state(state, smokers: smokers)
    Logger.info("Arbiter: PUT_SMOKE: new_state=#{inspect state}")
    schedule_smoke()
    {:noreply, state}
end


### Implementation

defp new_state(types) do
    smokers = for t <- types, into: %{}, do: {t, rec_smoker_state()}
    rec_state(smokers: smokers)
end


defp smokers_register(state, type, pid) do
    smokers = rec_state(state, :smokers)
    smoker_state = smokers[type]
    smokers = %{smokers | type => rec_smoker_state(smoker_state, smoker_pid: pid)}
    rec_state(state, smokers: smokers)
end


defp all_smokers_registered(state) do
    rec_state(state, :smokers) |> Enum.all?(fn {_,smoker_state} -> smoker_registered(smoker_state) end)
end


defp smoker_registered(rec_smoker_state(smoker_pid: pid)) when is_pid(pid), do: true
defp smoker_registered(rec_smoker_state(smoker_pid: nil)), do: false


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
        ({t, rec_smoker_state(amount: a) = sr}, acc) ->
            %{acc | t => rec_smoker_state(sr, amount: a+1)}
    end
    new_smokers = Enum.reduce(smokers, smokers, bump_amount)
    Logger.info("Arbiter: bumping amounts: new=#{inspect new_smokers}")
    new_smokers
end


end

