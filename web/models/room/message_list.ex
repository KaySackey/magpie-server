defmodule Room.MessageList do
  @moduledoc """
  Abstractions for dealing with lists of messages
  Keep in mind that we use Elixir lists internally so performance is as follows:

  - Insertion O(1)
  - Search O(n)
  - Access O(n)
  - Deletion O(1)

  MessageLists are immutable. You can't delete a message after sending it.
  """
  alias Room.Message
  alias Room.MessageList

  @compact_at 2000
  @target_size 1000

  defstruct [
  	last_message_pk: 0,
  	len: 0,
  	list: []
  ]

  def constructor do
    %MessageList{}
  end

	@doc """
	Return the underlying list
	"""
	@spec all(MessageList) :: List
	def all(mlist) do
	  mlist.list
	end

	@doc """
	Return the length of the underlying list
	"""
	@spec count(MessageList) :: Int
	def count(mlist) do
	  mlist.len
	end

	@doc """
  Add a message to a list
	"""
  @spec add(MessageList, Message) :: MessageList
  def add(mlist, message) do
  	len = mlist.len + 1
  	last_message_pk = message.pk
  	list = [ message | mlist.list]

		%MessageList{mlist | list: list, len: len, last_message_pk: last_message_pk}
  end

	@doc """
	Return the last added message
	"""
	@spec last(MessageList) :: MessageList
  def last(mlist) do
  	# In context, the last message posted to a room is actually the first element in our list
    List.first(mlist.list)
  end

	@doc """
	Replce a given message within the list
	"""
  @spec replace(MessageList, Message) :: MessageList
  def replace(mlist, message) do
		index = Enum.find_index(mlist.list, fn x -> x.pk == message.pk end)
		list = List.replace_at(mlist.list, index, message)
		%MessageList{mlist | list: list}
  end


	@doc """
	Compact the internal list to a certain size
	"""
	@spec compact(MessageList) :: MessageList
	def compact(mlist)  do
		cond do
			mlist.len <= 1000 -> mlist
			mlist.len > 1000 ->
				list = Enum.take(mlist.list, 1000)
				len  = 1000
				%MessageList{mlist | list: list, len: len}
		end
	end
end

defmodule Room.MessageListServer do
	@moduledoc """
  A process to store MessageList state
  """
	use ExActor.GenServer
	import ExActor.Delegator

	alias Room.MessageList

	defstart start_link(initial \\ %MessageList{}),
					 gen_server_opts: :runtime, do: initial_state(initial)

	delegate_to Room.MessageList do
		query all/1
		query last/1
		query count/1
		trans add/2
		trans replace/2
		trans compact/1
	end
end