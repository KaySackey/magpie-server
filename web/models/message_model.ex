defmodule Room.Message do
  alias Room.Message

  defstruct [
    pk: 0,
    username: nil,
    body: "",
    timestamp: nil,
    kind: "simple" # we have this here instead of part of the
  ]



  @spec new :: Message
  def new do
    timestamp = :os.system_time(:seconds)
    pk = timestamp
    %Message{timestamp: timestamp, pk: pk}
  end

  @spec simple :: Message
  def simple do
    %{ Message.new | kind: "simple" }
  end

  @spec system :: Message
  def system do
    %{ Message.new | username: "System", kind: "system" }
  end

  @spec welcome :: Message
  def welcome do
    %{ Message.system | body: "Welcome to the room" }
  end
end


