defmodule Room.UserData do
  @moduledoc """
  Room data specific to only one user.
  Stored in memory.
  """
  defstruct [
			pk: '',
			slug: '',
			topic: '',
			unseen_messages: 0,
			last_seen_message_pk: 0
  ]
end

defmodule Room.ChannelData do
  @moduledoc """
  Room data specific to a live channel instance. Shared amonst users
  """

  require Room.MessageList
  require Poison

	@derive {Poison.Encoder, only: [:pk, :slug, :topic, :description]}

  defstruct [
      pk: '',
      slug: '',
      topic: '',
      description: '',
      #user_count: 0,
      # Within the registry
      # The below will be replaced with active processes to manage them
      users: %{},
      messages: []
  ]


end

defmodule Room.Persistent do
  @moduledoc """
  Persistent data stored in Postgres
  """
  defstruct [
		pk: 0,
		slug: '',
    topic: '',
    creator: '',
    last_message_posted: '',
    user_count: 0
  ]
end

defmodule Room do
	alias Room.UserData
	alias Room.ChannelData
	alias Room.Persistent
	alias Room.RoomSupervisor

	def get_or_create_info(topic) do
		create_info(topic)
	end

	def create_info(topic) do
		require Slugger
		require UUID

		pk = UUID.uuid4()
		slug = Slugger.slugify_downcase(topic)
	  %ChannelData{pk: pk, slug: slug, topic: topic}
	end

	def get_or_create(topic) do
	  {room, info} = Room.Registry.get_or_create(:rooms, topic)
		{room, info}
	end

	def get(topic) do
		Room.Registry.lookup(:rooms, topic)
	end

  def all() do
  	Room.Registry.values(:rooms)
  	#[  %ChannelData{pk: 'lobby', topic: 'Lobby'}  ]
  end

	def delete(topic) do
	  Room.Registry.delete(:rooms, topic)
	end

  def history(room) do
  	alias Room.MessageListServer, as: MessageList
  	alias Room.Abstract.MapServer, as: UserMap

  	users = Room.users(room) |> UserMap.values
  	messages = Room.messages(room) |> MessageList.all

    %{users: users, messages: messages}
  end

	def users(room) do
	  RoomSupervisor.user_list(room)
	end

	def messages(room) do
		RoomSupervisor.message_list(room)
	end

	def add_message(room, message) do
	  alias Room.MessageListServer, as: MessageList
	  message_list = Room.messages(room)
	  message_list |> MessageList.add(message)
	end

	def add_user(room, user) do
		alias Room.User
		alias Room.Abstract.MapServer, as: UserMap

		user_map = Room.users(room)

		UserMap.get_and_update(user_map, user.username,
						fn nil -> {nil, user}
							 user -> {user, %User{user | logins: user.logins + 1} }
						end)


		{:ok, room}
	end


	def remove_user(room, user) do
		alias Room.User
		alias Room.Abstract.MapServer, as: UserMap

		user_map = Room.users(room)
		val = user_map |> UserMap.get(user.username)

		case val do
		  nil -> {:ok, room}
		  %{logins: 1} ->
		   	user_map |> UserMap.delete(user.username)
		   	{:ok, room}
		  user ->
		  	user_map |> UserMap.put(user.username, %User{user | logins: user.logins - 1})
		  	{:ok, room}
		end
	end

end