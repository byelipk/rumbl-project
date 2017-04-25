defmodule Rumbl.InfoSys.Supervisor do
  @moduledoc """
  An Elixir supervisor has just one purpose — it manages one or more worker
  processes including other supervisors.

  At its simplest, a supervisor is a process that uses the OTP supervisor
  behavior. It is given a list of processes to monitor and is told what to do
  if a process dies, and how to prevent restart loops (when a process is
  restarted, dies, gets restarted, dies, and so on).
  """
  use Supervisor # Use the Supervisor API

  def start_link() do
    IO.puts "HELLO #{__MODULE__}"
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    children = [
      worker(Rumbl.InfoSys.Application, [],
        restart: :temporary,    # child process is never restarted
        function: :start_link,  # function to invoke on the child to start it
      )
    ]

    # Our supervisor needs to dynamically supervise individual processes
    # so we will use the :simple_one_for_one strategy.
    supervise(children, strategy: :simple_one_for_one)
  end

end
