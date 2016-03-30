defmodule Magpie.OccupancyTest do
  use Magpie.ChannelCase
  require Logger
  alias Magpie.RoomChannel

  use Magpie.ChannelCase, async: true
  require Logger

  alias Magpie.RoomChannel

	require Room.RoomSupervisor
	require Room
	require Room.Registry


	setup do
		user = %Room.User{pk: UUID.uuid4(), username: "Testee"}
		with {:ok, socket} <- UserSocket.login(socket(), user),
				 {:ok, _reply, socket} <- subscribe_and_join(socket, RoomChannel, "rooms:lobby"),
				 do: {:ok, socket: socket}
	end


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



  @doc """

  Heatbeat Implementation

  Race Condition Issues (Client Side)

  - 1. User Leaves or timeout occurs
  - 2. Server says user has left
  - 3. User Returns
  - 4. Server says user has joined

  If message 4 arrives before message 2, then we’ll have a problem.

  We can try and solve this with message ordering. Client will explicitly know what message ID it is waiting on, and if it receives 4 before 2 then it will wait 10 seconds and perform a history check.



  Race Conditions Server Side

  1. User Joins
  2. User leaves
  3. User Joins

  Messages are received as 2, 1, 3.
  This can only happen because of a buggy or evil client.
  Server side... a user cannot leave a room they have not joined. No leave messages will be published.
  When 1 is received, user will join room.
  When 3 is received, user will attempt to join again but room list will not be updated.

  Perhaps 2 connections to the same channel might be created.

  """
  test "race conditions", %{socket: _socket} do

  end

end
