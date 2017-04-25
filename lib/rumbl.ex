defmodule Rumbl do
  use Application

  @doc """

  ## Sequence of evets

    * When our application starts, the start function is called.
    * It creates a list of child servers using the supervisor function.
    * Call Supervisor.start_link/2 to create the supervisor process.
    * Our supervisor calls start_link/2 for each of the managed children.

  """
  def start(_type, _args) do
    import Supervisor.Spec

    IO.puts "HELLO #{__MODULE__}"

    # Create the list of child processes our supervisor will manage.
    children = [
      supervisor(Rumbl.Repo, []),
      supervisor(Rumbl.Endpoint, []),
      supervisor(Rumbl.InfoSys.Supervisor, []),
    ]

    # A :one_for_one strategy means if any of our three managed supervisor
    # processes dies, it will be restarted.
    opts = [strategy: :one_for_one, name: Rumbl.Supervisor]

    # Create the supervisor process, and invoke start_link/2 for each
    # child process.
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Rumbl.Endpoint.config_change(changed, removed)
    :ok
  end
end
