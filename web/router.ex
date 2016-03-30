defmodule Magpie.Router do
  use Magpie.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

	pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/api/" do
    pipe_through [:api]

    get "/auth", Magpie.AuthController, :auth
    get "/rooms", Magpie.AuthController, :rooms
  end

  scope "/", Magpie do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Magpie do
  #   pipe_through :api
  # end
end
