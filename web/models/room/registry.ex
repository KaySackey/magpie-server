defmodule Room.Registry do
	@moduledoc """
	Defines the mapping of existing values (values) to their references (refs).
	"""
	defstruct [
		values: %{},
		refs: %{},
		name: nil
	]

	use GenServer
	require Logger
	require Process
	alias Room.Registry

	@child Room.RoomSupervisor


  @doc """
  Return an object to store within the registry
  """
  def _start_child(topic) do
    require Room
    info = Room.get_or_create_info(topic)

		# Place value holder under supervision tree
		# This ensures that its crashes will not affect us
    {:ok, room} = @child.start_link(info.slug)

    # Get a monitor to this process so the registry can cleanup
    ref = Process.monitor(room)

    {ref, {room, info}}
  end

  def start_link(registry_name) do
  	Logger.debug("DEBUG " <> inspect(registry_name))
    {:ok, _pid} = GenServer.start_link(__MODULE__, [registry_name], [name: registry_name])
  end

  def init(options) do
    	[registry_name] = options

  		state = %Registry{name: registry_name}
			{:ok, state}
  end


  def lookup(server, name) do
    reply = GenServer.call(server, {:lookup, name})
    reply
  end

  def create(server, name) do
  	#Logger.debug "Creating value named: " <> inspect(name)

    reply = GenServer.call(server, {:create, name})
    reply
  end

  def get_or_create(server, name) do
  	# Create is idepondent
  	create(server, name)
    {:ok, value} = lookup(server, name)
    value
  end

  def delete(server, name) do
  	#Logger.debug "Deleting value named: " <> inspect(name)

    reply = GenServer.call(server, {:delete, name})
    reply
  end

  def values(server) do
    GenServer.call(server, {:values})
  end

  ## Server Callbacks
  #####
	@doc """
	Look up a value
	"""
  def handle_call({:lookup, name}, _from, state) do
  	case state.values |> Map.fetch(name) do
  	  :error -> {:reply, :error, state}
  	  {:ok, {_ref, value} } ->
  				{:reply, {:ok, value}, state}
  	end
  end

	@doc """
	Return the map of values
	"""
  def handle_call({:values}, _from, state) do
    {:reply, state.values, state}
  end

	@doc """
	Create a new value
	"""
	def handle_call({:create, name}, _from, state) do
		# Todo; if this is generic we'd want to get the value somehow....
		# Maybe pass in value?

    if Map.has_key?(state.values, name) do
      {:reply, :ok, state}
    else
     	{ref, value} = _start_child(name)

			state = push(state, name, {ref, value}, ref)

      {:reply, :ok, state}
    end
  end

	@doc """
	Return the PID from a value
	"""
	def get_child_pid(value) do
		{room, _info} = value
		room
	end

	@doc """
	Delete by name.
	"""
  def handle_call({:delete, name}, _from, state) do
  		if Map.has_key?(state.values, name) do
  			{:ok, {monitor_ref, value} } = state.values |> Map.fetch(name)
  			pid = get_child_pid(value)

  			Process.exit(pid, :normal)
  			Process.demonitor(monitor_ref)

				# :EXIT is sent not :DOWN so we won't trap this.
				state = pop(state, monitor_ref)
  		end

  		{:reply, :ok, state}
  end
  
	@doc """
	Remove crashed value from registry.
	Delete by monitor reference.
	"""
  def handle_info({:DOWN, monitored_ref, :process, _monitored_pid, _reason}, state) do
  		state = pop(state, monitored_ref)
			{:noreply, state}
  end

  def handle_info(msg, state) do
      #IO.inspect(msg)
      {:noreply, state}
  end


	@spec push(Registry, Kernel.String, :pid, Kernel.Reference) :: Registry
	defp push(state, name, value, ref) do

			values = state.values |> Map.put(name, value)
			refs    = state.refs |> Map.put(ref, name)

			%Registry{state | values: values, refs: refs}
	end

	@spec pop(Registry, Kernel.Reference) :: Registry
	defp pop(state, ref) do
			{name, refs} = Map.pop(state.refs, ref)
			{_, values} = Map.pop(state.values, name)

			%Registry{state | values: values, refs: refs}
	end
end