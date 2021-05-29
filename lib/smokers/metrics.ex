defmodule Smokers.Metrics do

use GenServer
require Logger

defmodule State do
    defstruct [
        smoker_notified: %{},
        smoker_claimed: %{},
        smoker_claim_fail: %{},
        smoker_claim_ok: %{},
        arbiter_put: %{},
    ]
end


### API

def start_link() do
    GenServer.start_link(__MODULE__, nil, [name: :smokers_metrics])
end


def smoker_notified(type) do
    GenServer.cast(:smokers_metrics, {:smoker_notified, type})
end


### Callbacks

@impl true
def init(_) do
    state = %State{}
    Logger.info("METRICS: starting, state=#{inspect state}")
    schedule_print()
    {:ok, state}
end


@impl true
def handle_cast({:smoker_notified, type}, state) do
    Logger.info("METRIC: smoker_notified: type=#{inspect type}")
    {:noreply, state}
end


@impl true
def handle_info(:print_metrics, state) do
    Logger.info("METRIC_PRINT: state=#{inspect state}")
    schedule_print()
    {:noreply, state}
end


#defp metric_inc(state, metric_name, smoker_type, inc \\ 1) do
#    :ok
#end

def schedule_print() do
    :timer.send_after(7000, :print_metrics)
end


end

