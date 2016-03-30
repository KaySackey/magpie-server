defmodule Magpie.RoomModelTest do
  use Magpie.ChannelCase#, async: true

  require Logger
  alias Magpie.RoomChannel

	require Room
	require Room.Registry
	require Room.RoomSupervisor

	alias Room.User
	alias Room.Abstract.MapServer, as: UserMap
	alias Room.Message
	alias Room.MessageListServer, as: MessageList
  #test "removes bucket on crash", %{registry: registry} do
    #KV.Registry.create(registry, "shopping")
    #{:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with non-normal reason
    #Process.exit(bucket, :shutdown)

    # Wait until the bucket is dead
    #ref = Process.monitor(bucket)
    #assert_receive {:DOWN, ^ref, _, _, _}

    #assert KV.Registry.lookup(registry, "shopping") == :error
  #end


	test "creation" do
		assert :ok == Room.Registry.create(:rooms, "test-lobby0")
		{:ok, {room, info}} = Room.Registry.lookup(:rooms, "test-lobby0")
		assert info.topic == "test-lobby0"
	end

	test "get_or_create on Room facade" do
	  {room, info} = Room.get_or_create("random room")
	  assert info.topic == "random room"
	  assert info.slug == "random-room"
	end


	test "deletion on Room facade" do
	  {room, info} = Room.get_or_create("test-lobby-to-delete")
	  Room.delete("test-lobby-to-delete")
	  assert :error == Room.get("test-lobby-to-delete")
	end

	test "adding user" do
	   {room, info} = Room.get_or_create("test-lobby1")

		user = User.get_test_user()
		Room.add_user(room, user)

		# Add user once
		assert (Room.users(room) |> UserMap.count) == 1
		assert (Room.users(room) |> UserMap.get(user.username)) == user

		# Add them multiple times to see the login count goes up
		Room.add_user(room, user)
		Room.add_user(room, user)

		assert (Room.users(room) |> UserMap.count) == 1
		assert (Room.users(room) |> UserMap.get(user.username)) == %{user | logins: 3}

		# Remove the user
		Room.remove_user(room, user)
		assert (Room.users(room) |> UserMap.get(user.username)) == %{user | logins: 2}

		Room.remove_user(room, user)
		assert (Room.users(room) |> UserMap.get(user.username)) == %{user | logins: 1}

		Room.remove_user(room, user)
		assert (Room.users(room) |> UserMap.count) == 0
		assert (Room.users(room) |> UserMap.get(user.username)) == nil
	end

	test "adding message" do
	  Room.Registry.create(:rooms, "test-lobby2")

	  user = User.get_test_user()
	  message = %Room.Message{username: user.username, body: "Hello World", kind: "simple"}

		{:ok, {room, info}} = Room.get("test-lobby2")

		Room.add_message(room, message)
		assert (Room.messages(room) |> MessageList.count) == 1
		assert (Room.messages(room) |> MessageList.last) == message

		# Test history
		%{users: users, messages: messages} = Room.history(room)
		assert length(messages) == 1
		assert List.first(messages) == message
	end

	test "sanity check" do
		{room, info} = Room.get_or_create("test-lobby3")

		user = User.get_test_user()
		message = %Room.Message{username: user.username, body: "Hello World", kind: "simple"}

		Room.add_message(room, message)

		# Adding a message doesn't necessary add that user to the room
		assert (Room.users(room) |> UserMap.count) == 0
	end

	test "restart" do
		# Kill the registry and see if it restarts with the rooms that were previously present

		# Kill the user bucket and see if the messages are still intact

		# Kill the message and see if the users are still intact

		# Kill the registry supervisor
	end

	test "clean up" do
		# Registry should be cleaned up ever X seconds
		# Any rooms not updated by that point should be dropped from listings
	end

	test "race conditions" do
		# No test here, just possibilities

		# 1. User joins room
		# 2. User sends message to server
		# 3. Room registry dies and is restarted
		# 4. At this point the user is not listed as being in the room; but they're a part of the channel
		#		 So adding their message will result in a user who is listed in messages; but not in users
	end
end
