defmodule KV.MapServer do
	@moduledoc """
  A process to store state within a map
  """
	use ExActor.GenServer
	import ExActor.Delegator
	defstart start_link(initial \\ %{}),
					 gen_server_opts: :runtime, do: initial_state(initial)

 	delegate_to Map do
		query get/2
		query values/1
		trans put/3
		trans delete/2
	end

	delegate_to Enum do
	  query count/1
	end

  defcall get_and_update(key, fun), state: state do
    {old_value, state} = Map.get_and_update(state, key, fun)
    set_and_reply(state, {old_value, state})
  end
end

defmodule KV.MapSupervisor do
	@moduledoc """
	EXAMPLE.

  A Supervisor over maps.
  """
  use Supervisor

  # A simple module attribute that stores the supervisor name
  def start_link(name) do
    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  def start_bucket(supervisor) do
    Supervisor.start_child(supervisor, [])
  end

  def init(:ok) do
    children = [
    	# Worker is :temporary because the creation of buckets should always
    	# pass through the registry
      worker(KV.MapServer, [], restart: :temporary),
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end