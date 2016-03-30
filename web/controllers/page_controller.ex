defmodule Magpie.PageController do
  use Magpie.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def send_to_admin(conn, %{"uid" => uid, "body" => body} = _params) do
      # Send a message to the admin room
      Magpie.Endpoint.broadcast! "rooms:admin", "new_msg", %{uid: uid, body: body}
      json conn, %{response: 'ok'}
  end


end
