defmodule Magpie.UserSocket do
  use Phoenix.Socket
  require Logger
  require Guardian
  alias Room.User
  require Poison
  require Helpers

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Magpie.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  #def id(_socket), do: nil
	def id(socket), do: "users_socket:#{socket.assigns.username}"

  ## Channels
  channel "rooms:lobby", Magpie.RoomChannel
  channel "rooms:*", Magpie.RoomChannel
  channel "system", Magpie.SystemChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket) do
    #Logger.debug "Connection: #{inspect(params)}"
    #Logger.debug "Connection: #{inspect(socket)}"

		# Login
		result = with \
						{:ok, user} <- auth(params["jwt"]),
						{:ok, socket} <- login(socket, user),
						do: {:ok, socket}

		# Error checking
	  case result do
	  	{:ok, socket} -> {:ok, socket}
	  	{:error, :invalid_token} -> {:error, "Invalid token"}
      {:error, err} ->
      	Logger.debug inspect(err)
      	{:error, "Invalid User"}
			other -> other
	  end
  end

  @spec auth(any) :: {:error, :invalid_token} | {:ok, User}
  def auth(jwt) do
  		with \
  			{:ok, decoded} <- Guardian.decode_and_verify(jwt)
				do
				 	user = User.new(decoded["sub"])
					{:ok, user}
				end
	end

	@spec login(Socket, User) :: Socket
  def login(socket, user) do
    socket = socket |> assign(:username, user.username)
					 					|> assign(:user, user)

		socket = set_room_id(socket, nil)

		{:ok, socket}
  end

  def authenticated?(socket) do
			socket.assigns.user != nil
  end

	def user(socket) do
		socket.assigns.user
	end

	def set_room_id(socket, room_id) do
    socket = socket |> assign(:room_id, room_id)
    socket
	end

  @doc """
  Disconnect this user from all named sockets
  """
  def disconnect_all(user) do
    # Kick user from all rooms
    Magpie.Endpoint.broadcast("users_socket:#{user.username}", "disconnect", %{})
  end
end