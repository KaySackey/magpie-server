defmodule Magpie.RoomChannelTest do
  use Magpie.ChannelCase, async: true
  require Logger

  alias Magpie.RoomChannel


  setup do
  	user = %Room.User{pk: UUID.uuid4(), username: "Testee"}
  	with {:ok, socket} <- UserSocket.login(socket(), user),
  			 {:ok, _reply, socket} <- subscribe_and_join(socket, RoomChannel, "rooms:lobby"),
  			 do: {:ok, socket: socket}
  end

  #setup %{simple: true} = tags do
  #  IO.puts ("simple setup!!")
  #  :ok
  #end

	@tag :simple
  test "socket_setup", %{socket: socket} do
  	assert socket.assigns.user.username == "Testee"
  end

	@tag :simple
  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end

	@tag :simple
	@tag :message
  test "simple_message broadcasts to rooms:lobby", %{socket: socket} do
		import UserSocket
		require Room.Message

		uname = UserSocket.user(socket).username
		push socket, "simple_message", %{"text" => "all"}
    assert_broadcast "simple_message", %Room.Message{username: uname, body: "all", kind: "simple"}
  end

	@tag :simple
	@tag :message
	@tag timeout: 500
  test "room action", %{socket: socket} do
    ref = push(socket, "command", %{"text" => "/users"})
    assert_reply(ref, :ok, message)

    # Since commands can take some time, let's wait to see if the message has come through
    assert_push "system_message", %Room.Message{username: "System", kind: "system"}
  end

	@tag timeout: 500
  test "auth", %{socket: socket} do
		alias Room.User
		fake = User.get_test_user()
		{:ok, jwt, _full_claims } = Guardian.encode_and_sign(fake, :chat, [aud: "Magpie"])

		params = %{"jwt" => jwt}
		{:ok, socket} = connect(UserSocket, params)
		assert UserSocket.authenticated?(socket) == true
  end
end
