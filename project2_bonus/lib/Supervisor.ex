defmodule ProjectSupervisor do
    use Supervisor
    def start_link(args) do
        Supervisor.start_link(__MODULE__, args)
        {:ok, args}
    end
    def init(args) do
        children = [
            worker(WorkerManager, args)
        ]
        supervise(children, strategy: :one_for_one)
    end
end