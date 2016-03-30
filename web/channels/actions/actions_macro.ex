defmodule Actions do
	defmacro __using__(_opts) do

		quote do
			import Actions
			require Logger
			require Phoenix.Channel
			require BirdSong
			alias Actions.ErrorMessages, as: Err

			# Initialize @tests to an empty set
			#@before_compile Actions
			@valid_commands Map.new()
			@handler __MODULE__
 			@before_compile Actions

			Logger.debug "Compiling ::: #{@handler}"

			@doc """
			Given a command string and socket, convert it to an AST and dispatch commands based on this.
			Return a socket, with a message optionally attached to it
			"""
			@spec handle(String.t, Phoenix.Channel.Socket) :: Phoenix.Channel.Socket
			def handle(text, socket) do

			 	results =
					with {:ok, ast} <- BirdSong.ast(text),
							 {:ok, msg} <- @handler.handle_command(ast, socket),
							 do: {:ok, msg}

				# Because we are in a macro, we can't just pipe results to errors
			 	case results do
			 		# Success
			 		{:ok, msg} -> msg

					# Handle Errors
					{:error, :argument_needed} -> Err.no_argument_error
					{:error, :invalid_command} -> Err.invalid_command
					{:error, reason} -> Err.invalid_command # reason would come from lexer / parser
					_ -> Err.invalid_command
				end
					# Push msg to socket
					|> push_msg(socket)
			end

			def push_msg(msg, socket) do
				Logger.debug "Pushing .... #{inspect(msg)}"
				Phoenix.Channel.push(socket, "system_message", msg)
				socket
			end
		end
	end

	defmacro cmd(name, a1, do: block) do
		quote do
		  @valid_commands Map.put(@valid_commands, unquote(name), 1)
			#IO.puts(IO.ANSI.green <> inspect(@valid_commands) <> IO.ANSI.reset)

			def run(unquote(name), unquote(a1)) do
			  unquote(block)
			end
		end
	end

	defmacro cmd(name, a1, a2, do: block) do
		#IO.inspect(name)
		#IO.inspect(a1)
		#IO.inspect(a2)

		quote do
		  @valid_commands Map.put(@valid_commands, unquote(name), 2)
			#IO.puts(IO.ANSI.green <> inspect(@valid_commands) <> IO.ANSI.reset)

			def run(unquote(name), unquote(a1), unquote(a2)) do
			  unquote(block)
			end
		end
	end

	# This will be invoked right before the target module is compiled
  # giving us the perfect opportunity to inject the `run/0` function
  @doc false
  defmacro __before_compile__(env) do
    quote do
      def handle_command(ast, socket) do
				# Ast should look something like this: {"command_name", ["argument"]}
				{command, args} = ast

				Logger.debug "Here : #{inspect(@valid_commands)}"

				# Args should be at most length 1
				# Arity of commands begins at 1 b/c we always pass socket to the command
				case Map.get(@valid_commands, command, -1) do
					-1 ->
							{:error, :invalid_command}
					1  ->
							{:ok, msg} = @handler.run(command, socket)
							{:ok, msg}
					2  ->
						unless length(args) == 0 do
							{:ok, msg} = @handler.run(command, socket, hd(args))
							{:ok, msg}
						else
							{:error, :argument_needed}
						end
				end
			end

			defoverridable push_msg: 2, handle: 2, handle_command: 2
    end # quote end
  end # macro end

end # module end