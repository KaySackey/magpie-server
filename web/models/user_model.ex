defmodule Room.User do
  defstruct [
      pk: 1,
      username: "No one",
      avatar: "http://lorempixel.com/100/100/people/1/",
      status: "member",
      logins: 1
  ]

	alias Room.User
  require UUID
  require Poison
	use ExConstructor, [camelcase: false, underscore: false]

	@derive {Poison.Encoder, only: [:pk, :username, :avatar]}
  @derive [Enumerable]

  @spec from_username(String) :: User
  def from_username(username) do
    %User{pk: UUID.uuid4(), username: username}
  end

  def get_test_user() do
    %User{pk: 0, username: "Testee", avatar: "http://lorempixel.com/100/100/people/1/"}
  end
end