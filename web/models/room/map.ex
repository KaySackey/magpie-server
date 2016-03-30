defmodule Room.Abstract.MapServer do
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