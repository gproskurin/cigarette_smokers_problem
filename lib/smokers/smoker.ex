defmodule Smokers.Smoker do

alias Smokers.Arbiter, as: Arbiter

use GenStateMachine, callback_mode: :handle_event_function
require Logger


defmodule Data do
    defstruct [
        type: nil,
        arbiter_pid: nil,
        need_check_claim: false
    ]
end

@time_smoke 10000

### API

def start_link(type) do
    GenStateMachine.start_link(__MODULE__, type)
end


def check(smoker_pid) do
    GenStateMachine.cast(smoker_pid, :ev_check)
end


def registered(smoker_pid) do
    GenStateMachine.cast(smoker_pid, :ev_registered)
end


### Callbacks

@impl true
def init(type) do
    arbiter_pid = Arbiter.get_pid()
    data = %Data{
        type: type,
        arbiter_pid: arbiter_pid
    }
    Logger.info("SMOKER init: data=#{inspect data}")
    :ok = Arbiter.register_smoker(arbiter_pid, type, self())
    {:ok, :st_wait_registration, data}
end


@impl true
def handle_event(:cast, :ev_registered, :st_wait_registration, data) do
    Logger.info("SMOKER: ev_registered data=#{inspect data}")
    {:next_state, :st_wait, data}
end
def handle_event(_, ev, :st_wait_registration, data) do
    Logger.info("SMOKER: event while waiting: ev=#{inspect ev} data=#{inspect data}")
    {:keep_state_and_data, [:postpone]}
end

def handle_event(:cast, :ev_check, :st_wait, data) do
    Smokers.Metrics.smoker_notified(data.type)
    Logger.info("EVENT: check data=#{inspect data}")
    data = %{data | need_check_claim: false}
    case Arbiter.claim(data.arbiter_pid, data.type) do
        :claim_ok ->
            Logger.info("CLAIM_OK: data=#{inspect data}")
            {:next_state, :st_smoking, data, [{:state_timeout, @time_smoke, :ev_smoke_timeout}]}
        :claim_fail ->
            Logger.info("CLAIM_FAIL: data=#{inspect data}")
            {:keep_state, data}
    end
end

def handle_event(:state_timeout, :ev_smoke_timeout, :st_smoking, data) do
    Logger.info("TIMEOUT while smoking: data=#{inspect data}")
    {:next_state, :st_wait, data}
end
def handle_event(ev_type, :ev_check, :st_smoking, data) do
    case data.need_check_claim do
        true ->
            # avoid duplicating ev_check events
            Logger.info("SMOKER: duplicate check prevented, data=#{inspect data}")
            :keep_state_and_data
        false ->
            new_data = %{data | need_check_claim: true}
            Logger.info("SMOKER: postpone check, old_data=#{inspect data} new_data=#{inspect new_data}")
            {:keep_state, new_data, [:postpone]}
    end
end
def handle_event(ev_type, ev, :st_smoking, data) do
    Logger.info("EVENT while smoking: ev_type=#{inspect ev_type} ev=#{inspect ev} data=#{inspect data}")
    {:keep_state_and_data, [:postpone]}
end


end

