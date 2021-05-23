defmodule Smokers.Arbiter do

use GenServer
require Logger
require Record

Record.defrecord(:state, smokers: nil)
Record.defrecord(:smoker_state, smoker_pid: nil, amount: 0)

def start_link(types) do
    GenServer.start_link(__MODULE__, types, [name: __MODULE__])
end


def register_smoker(arbiter_pid, type, smoker_pid) do
    GenServer.cast(arbiter_pid, {:register_smoker, type, smoker_pid})
end


@impl true
def init(types) do
    state = new_state(types)
    Logger.info("Starting arbiter: state=#{inspect(state)} self=#{inspect(self())}")
    {:ok, state}
end


@impl true
def handle_cast({:register_smoker, type, smoker_pid}, state) do
    smoker_state = state(state, :smokers)[type]
    new_smokers = Map.put(
        state(state, :smokers),
        type,
        smoker_state(smoker_state, smoker_pid: smoker_pid)
    )
    new_state = state(state, smokers: new_smokers)
    Logger.info("Arbiter - registering smoker: old_state=#{inspect(state)} new_state=#{inspect(new_state)}")
    Smokers.Smoker.registered(smoker_pid)
    Logger.info("Arbiter: all? #{inspect(all_smokers_registered(new_state))}")
    {:noreply, new_state}
end


defp new_state(types) do
    smokers = for t <- types, into: %{}, do: {t, smoker_state()}
    state(smokers: smokers)
end


defp all_smokers_registered(state) do
    # FIXME fn
    state(state, :smokers) |> Enum.all?(fn {_,smoker_state} -> smoker_registered(smoker_state) end)
end


defp smoker_registered(smoker_state) do
    smoker_state(smoker_state, :smoker_pid) != nil
end


end

