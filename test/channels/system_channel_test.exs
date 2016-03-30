defmodule Magpie.SystemChannelTest do
  use Magpie.ChannelCase, async: true

  alias Magpie.SystemChannel

  setup do
  	user = %Room.User{pk: UUID.uuid4(), username: "Testee"}
  	with {:ok, socket} <- UserSocket.login(socket(), user),
  			 {:ok, _reply, socket} <- subscribe_and_join(socket, SystemChannel, "system"),
  			 do: {:ok, socket: socket}
  end



  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to system", %{socket: socket} do
    push socket, "shout", %{"hello" => "all"}
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end
end
