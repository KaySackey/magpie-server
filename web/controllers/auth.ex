defmodule Magpie.AuthController.Counter do
  use ExActor.Tolerant, export: :auth_counter

	defstart start(initial \\ 1) do
		initial_state(initial)
	end

  defcast incr(), state: state, do: new_state(state + 1)
  defcast decr(), state: state, do: new_state(state - 1)

	defcall val(), state: state, do: reply(state)

	defcall next(), state: state, do: set_and_reply(state + 1, state + 1)
end

#{:ok, _} = Magpie.AuthController.Counter.start(0)

defmodule Magpie.AuthController do
  use Magpie.Web, :controller

	#plug Guardian.Plug.EnsureAuthenticated, on_failure: { SessionController, :unauthenticated_api }
	alias Magpie.AuthController.Counter

  def auth(conn, _params) do
  		require Mix
			alias Room.User

			Magpie.AuthController.Counter.start(0)
			username = "Hera #{Counter.next()}"

  		fake = User.from_username(username)
			{:ok, jwt, _full_claims } = Guardian.encode_and_sign(fake, :chat, [aud: "Magpie"])

			auth_config = Application.get_env(:magpie, :auth)
  		case auth_config[:allow_faker] do
  		  false -> json(conn, %{status: "error", reason: "Faker has been disabled."})
  		  true -> json(conn, %{status: "ok", user: fake, jwt: jwt})
  		end
  end

  def rooms(conn, _params) do
  		require Mix
			require Room

			rooms = [
      	Room.get_or_create("Lobby"),
      	Room.get_or_create("Roleplay")
      ] |> Enum.map(fn {room, info} ->
      	info
      end)

      json(conn, %{
      	"rooms" => rooms
      });
  end
end
