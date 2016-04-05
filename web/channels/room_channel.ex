defmodule Magpie.RoomChannel do
  use Magpie.Web, :channel

	require Message
  require Logger
  require Room
  require Plug.HTML
  alias Magpie.UserSocket

  # TODO: http://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect
  # If client goes away, I'm not 100% sure that we will get a termination signal
  # PHX will know b/c it sends heartbeats to/from server/client but will loss of hearbeat kill this channel?
  ####

	@doc """
	Join the lobby. Everyone can join the lobby.
	"""
  def join("rooms:lobby" = _topic, _payload, socket) do
		room_id = "lobby"
		{:ok, %{users: users, messages: messages}, socket} = __join_room(room_id, socket)

		{:ok, %{users: users, messages: messages}, socket}
  end

	@doc """
	Join a specific room
	"""
  def join("rooms:" <> room_id, _payload, socket) do
  	__join_room(room_id, socket)
  end

	@doc """
	Handle join requests to non-existant locations
	"""
  def join(_topic, _payload, _socket) do
    {:error, %{reason: "does not exist"}}
  end

  def __join_room(room_id, socket) do
  	Logger.debug "#{socket.assigns.username} | Joining room #{room_id}"

		user = socket.assigns.user
		socket = UserSocket.set_room_id(socket, room_id)

		# Add user to the room
	 	{room, _info} = Room.get_or_create(room_id)
		Room.add_user(room, socket.assigns.user)

		# Trap Exits
		#spawn_link(fn ->
	#		ref = Process.monitor(self())
	#		Logger.debug "Trapping #{inspect(ref)} - #{inspect(self())}"
#			receive do
#			  {:DOWN, _ref, :process, _pid, _reason} ->
#			  	Logger.debug "#{_pid} |  Leaving room #{room_id} - Reason: #{Kernel.inspect(_reason)}"
#			   msg ->
#			   	Logger.debug "#{ref} |  Leaving room #{room_id} - Reason: NO?"
#			end
#		end)

		# Get History
		%{users: users, messages: messages} = Room.history(room)
		rooms = Room.all()

		#IO.inspect rooms

		# Inform everyone the user has joined the room
		send(self, {:after_join, user})

		{:ok, %{users: users, messages: messages}, socket}
  end


  def terminate(msg, socket) do
  	# If any of the callbacks return a :stop tuple. this will also be called
    # {:shutdown, :left | :closed} | term
    Logger.debug "#{socket.topic} - Terminate " <> inspect(msg)
    handle_leave(socket.topic, socket)

    socket
  end

	def handle_leave("rooms:" <> room_id, socket) do
      user = socket.assigns.user

	 		{room, info} = Room.get_or_create(room_id)
			Room.remove_user(room, user)
			broadcast! socket, "user:left", %{user: user}
  end

  def handle_in("history", socket) do
  	# Todo: Find out if a socket in multiple rooms still has a valid topic
  	{room, _info} = Room.get_or_create(socket.assigns.room_id)
		%{users: users, messages: messages} = Room.history(room)

    push socket, "history", %{users: users, messages: messages}
  end

  def broadcast_message!(socket, message) do
		{room, _info} = Room.get_or_create(socket.assigns.room_id)

    # Add to history
    Room.add_message(room, message)

    # Send it out to the world
    event = message.kind <> "_message"
    broadcast! socket, event, message

    socket
  end

  @doc """
  Broadcast simple text messages
  """
  def handle_in("simple_message", %{"text" => text } = _payload, socket) do
  	text = Plug.HTML.html_escape(text)
		message = %{ Message.simple | username: socket.assigns.username, body: text }

		broadcast_message!(socket, message)

		{:reply, :ok, socket}
  end

	@doc """
	Handle basic commands to the server
	"""
  def handle_in("command", %{"text" => text} = _payload, socket) do
  		text = Plug.HTML.html_escape(text)
			socket = RoomActions.handle(text, socket)
			{:reply, :ok, socket}
  end

  @doc """
  If the occupancy handler falls behind in its messages; or is crashed it will ask all the subscribers to this channel
  to send a signal that they are still alive.
  """
  def handle_in("track_me", _payload, socket) do
   	{room, _info}= Room.get_or_create(socket.assigns.room_id)
   	Room.add_user(room, socket.assigns.user)
   	{:reply, :ok, socket}
  end

  intercept ["user:entered"]

	@doc """
	Interecept user:entered and do not send user:entered events to the user who created them.
	"""
  def handle_out("user:entered", %{user: user} = msg, socket) do
    unless socket.assigns.user.pk == user.pk do
      push socket, "user:entered", msg
    end

    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  def handle_info({:create_post, _attrs}, _socket) do
    #changeset = Post.changeset(%Post{}, attrs)

    #if changeset.valid? do
    #  Repo.insert!(changeset)
    #  {:reply, {:ok, changeset}, socket}``
    #else
    #  {:reply, {:error, changeset.errors}, socket}
    #end
  end

  def handle_info({:after_join, user}, socket) do
    # push to all clients
    broadcast! socket, "user:entered", %{user: user}

    # push back to client
    # push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
      IO.inspect(msg)
      {:noreply, socket}
  end
end
