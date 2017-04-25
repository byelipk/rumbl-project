defmodule Rumbl.InfoSys.Application do
  @backends [Rumbl.InfoSys.Wolfram]

  @doc """
  Proxy start link to each backend.

  How can we create a single worker that knows how to start a variety of
  backends?

  Our generic start_link will proxy individual start_link functions for each of
  our backends.
  """
  def start_link(backend, query, query_ref, owner, limit) do
    IO.puts "HELLO #{__MODULE__}"
    backend.start_link(query, query_ref, owner, limit)
  end

  @doc """
  Entry point into the information service.

  When a user makes a query, our supervisor will start up as many different
  queries as we have backends. Then, we’ll collect the results from each and
  choose the best one to send to the user.
  """
  def compute(query, opts \\ []) do
    limit    = opts[:limit] || 10
    backends = opts[:backends] || @backends

    backends
    |> Enum.map(&spawn_query(&1, query, limit))
    |> await_results(opts)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts      = [backend, query, query_ref, self(), limit]

    # Dynamically add a child managed by InfoSys.Supervisor.
    IO.puts "SPAWN_QUERY"
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)

    # Monitor the child process so we can take action if it crashes. We
    # don't want a crash to take down our supervisor, we just want to
    # know when it goes down. For that reason we use a monitor over
    # a link.
    monitor_ref = Process.monitor(pid)

    {pid, monitor_ref, query_ref}
  end


  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000
    timer = Process.send_after(self(), :timedout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do

      # We want to receive the next valid result in our inbox. When we
      # get one we drop our monitor. The [:flush] option guarentees
      # that the :DOWN message is removed from our inbox in case it's
      # delivered before we drop the monitor. We recurse and add
      # the result to our accumulator.
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)

      # When you monitor a process, you receive a :DOWN message when it exits
      # or fails, or if it doesn’t exist. If the process goes down we'll just
      # continue with the recursion - no big deal.
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)

      :timedout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)

    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timedout -> :ok
    after
      0 -> :ok
    end
  end
end
