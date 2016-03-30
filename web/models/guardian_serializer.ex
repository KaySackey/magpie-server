defmodule Magpie.GuardianSerializer do
    @behaviour Guardian.Serializer
		require Logger
    alias Room.User

    def for_token(user = %User{}) do
			{:ok, user }
    end

    def for_token(token) do
    	{:ok, token}
      #{:error, "Unknown resource type"}
    end

    def from_token(token) do
    	 Logger.debug "Token ::: " <> inspect(token)
			 {:ok, User.from_json(token) }
    end

    #def from_token(_) do
    #  {:error, "Unknown resource type"}
    #end
end