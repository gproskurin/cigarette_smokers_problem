defmodule Smokers.Arbiter do

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
    smoker_state = rec_state(state, :smokers)[type]
    new_smokers = Map.put(
        rec_state(state, :smokers),
        type,
        rec_smoker_state(smoker_state, smoker_pid: smoker_pid)
    )
    new_state = rec_state(state, smokers: new_smokers)
    Logger.info("Arbiter - registering smoker: old_state=#{inspect(state)} new_state=#{inspect(new_state)}")
    Smokers.Smoker.registered(smoker_pid)
    Logger.info("Arbiter: all? #{inspect(all_smokers_registered(new_state))}")
    {:noreply, new_state}
end


### Implementation

defp new_state(types) do
    smokers = for t <- types, into: %{}, do: {t, rec_smoker_state()}
    rec_state(smokers: smokers)
end


defp all_smokers_registered(state) do
    rec_state(state, :smokers) |> Enum.all?(fn {_,smoker_state} -> smoker_registered(smoker_state) end)
end


defp smoker_registered(rec_smoker_state(smoker_pid: pid)) when is_pid(pid), do: true
defp smoker_registered(rec_smoker_state(smoker_pid: nil)), do: false


end

