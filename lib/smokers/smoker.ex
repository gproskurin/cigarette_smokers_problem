defmodule Smokers.Smoker do

use GenServer
require Logger

@sleep_time 1000


def start_link(type, arbiter_pid) do
    GenServer.start_link(__MODULE__, {type, arbiter_pid})
end


def registered(smoker_pid) do
    GenServer.cast(smoker_pid, :registered)
end


@impl true
def init({type, arbiter_pid}) do
    state = %{
        type: type,
        arbiter_pid: arbiter_pid
    }
    {:ok, state, {:continue, :register_smoker}}
end


@impl true
def handle_continue(:register_smoker, state) do
    :ok = Smokers.Arbiter.register_smoker(
        state.arbiter_pid,
        state.type,
        self()
    )
    {:noreply, state}
end


@impl true
def handle_cast(:registered, state) do
    Logger.info("Smoker: registered, state=#{inspect(state)}")
    {:noreply, state}
end


defp smoke() do
    :timer.sleep(@sleep_time)
end


end
