defmodule Magpie.SystemChannel do
  use Magpie.Web, :channel

  def join("system", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join( _topic, _payload, socket) do
		{:ok, socket}
  end


  # Todo
  # Handle prescence via this channel

  # Todo
  # Handle request for all rooms via this channel

  # Todo
  # Handle room creation via this channel

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("send_to_admin", %{"uid" => uid, "body" => body}, socket) do
    # Send messages directly to the admins, wherever they may be.

    broadcast_from! socket, "new_msg", %{uid: uid, body: body}

    Magpie.Endpoint.broadcast_from! self(), "rooms:admin",
      "new_msg", %{uid: uid, body: body}
    {:noreply, socket}
  end


  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (systems:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
