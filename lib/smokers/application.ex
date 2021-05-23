defmodule Smokers.Application do

use Application
require Logger

@types [:tobacco, :paper, :match]

@impl true
def start(_, _) do
    Logger.info("Starting app, types=#{inspect(@types)}")
    Smokers.Supervisor.start_link(@types)
end

end



defmodule Smokers.Supervisor do

use Supervisor
require Logger

@supervisor __MODULE__

def start_link(types) do
    # start empty supervisor
    sup = Supervisor.start_link(__MODULE__, nil, [name: @supervisor])
    Logger.info("Started supervisor: result=#{inspect(sup)}")
    {:ok, sup_pid} = sup

    # start arbiter, get its pid
    spec_arbiter = %{
        id: :arbiter,
        start: {Smokers.Arbiter, :start_link, [types]}
    }
    {:ok, arbiter_pid} = start_child(sup_pid, spec_arbiter)

    # start smokers, pass arbiter's pid
    for type <- types do
        spec = %{
            id: {:smoker, type},
            start: {Smokers.Smoker, :start_link, [type, arbiter_pid]}
        }
        {:ok, _} = start_child(sup_pid, spec)
    end
    Logger.info("Started all children")
    sup
end


@impl true
def init(_) do
    flags = %{
        strategy: :one_for_all
    }
    {:ok, {flags, []}}
end


defp start_child(sup_pid, spec) do
    case Supervisor.start_child(sup_pid, spec) do
        {:ok, pid} when is_pid(pid) -> {:ok, pid}
        {:ok, pid, _info} when is_pid(pid) -> {:ok, pid}
    end
end

end
