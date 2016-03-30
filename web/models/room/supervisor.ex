defmodule Room.RoomSupervisor do
	@moduledoc """
  Encapsulates a single room
  """
  use Supervisor

  # A simple module attribute that stores the supervisor name
  def start_link(name) do
    {:ok, ref} = Supervisor.start_link(__MODULE__, [name])
    {:ok, ref}
  end

  def init(name) do
  	user_list_name = String.to_atom(to_string(name) <> "_users")
  	message_list_name = String.to_atom(to_string(name) <> "_messages")

    children = [
      worker(Room.Abstract.MapServer, [], restart: :permanent, id: :users),
      worker(Room.MessageListServer, [], restart: :permanent, id: :messages),
    ]

    supervise(children, strategy: :one_for_one)
  end

	# Delegate all state to the children
	# e.g. to get list of users:
	#
	#  room.occupancy() |> Occupancy.users
	#
	def user_list(supervisor) do
		get_child(supervisor, :users)
	end

	# Delegate all state to the children
	# e.g. to get list all messages:
	#
	#  room.message_list() |> MessageList.all
	#
	def message_list(supervisor) do
		get_child(supervisor, :messages)
	end

	def get_child(supervisor, requested_atom) do
	  {requested_atom, pid, _type, _spec} =
	  	Supervisor.which_children(supervisor)
	  	|> Enum.filter(fn {id, pid, _type, _modules} -> id == requested_atom end)
	  	|> List.first

	  pid
	end
end