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
    Supervisor.start_link(__MODULE__, types, [name: @supervisor])
end


@impl true
def init(types) do
    spec_metrics = %{
        id: :metrics,
        start: {Smokers.Metrics, :start_link, []}
    }

    spec_arbiter = %{
        id: :arbiter,
        start: {Smokers.Arbiter, :start_link, [types]}
    }

    smokers = for type <- types do
        %{
            id: {:smoker, type},
            start: {Smokers.Smoker, :start_link, [type]}
        }
    end

    children = [spec_metrics, spec_arbiter | smokers]
    Logger.info("SUP: children=#{inspect children}")
    flags = %{strategy: :one_for_all} # TODO do not restart metrics on failure
    {:ok, {flags, children}}
end


end

