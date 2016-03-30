defmodule RoomActions do
  @moduledoc """
  Defines actions that can be carried out within a room.
  """
  use Actions
  require Logger
  require Room
	alias Room.Message, as: Message

	@doc """
	Kick a user from this room.
	Usage: /kick "<username>"
	Example: /kick "Hera"
	"""
  cmd  "kick", _socket, _user do
  		msg = %{ Message.system | body: "I don't know how to kick people yet" }
			{:ok, msg}
  end

  cmd "users", socket do
    	alias Room.Abstract.MapServer, as: UserMap
  		topic = socket.assigns.room_id
  		{:ok, {room, _info}} = Room.get(topic)
    	user_list = Room.users(room) |> UserMap.values
  		user_list = user_list |> Enum.map(fn u -> u.username end) |> Enum.join(",")
  		msg = %{ Message.system | body: "You are in the room with: #{user_list}" }
  		{:ok, msg}
  end

  cmd "rooms", _socket do
  		rooms_list = Room.all() |> Enum.join(",")
  		msg = %{ Message.system | body: "You can join: #{rooms_list}" }
  		{:ok, msg}
  end

  cmd "invite", _socket, _user do
  		msg = %{ Message.system | body: "I don't know how to invite people yet" }
  		{:ok, msg}
  end
end