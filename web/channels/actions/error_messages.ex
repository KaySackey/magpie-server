defmodule Actions.ErrorMessages do
		alias Room.Message

  	def invalid_command do
  			body = ~s(I just tried to execute that as a command, but couldn't undrestand it. Commands are anything with a / infront of it.)
  			msg = %{ Message.system | body: body }
  	end

  	def no_argument_error do
  			body = ~s(I just tried to execute that as a command, but it didn't have an argument.)
  			msg = %{ Message.system | body: body }
  	end
end