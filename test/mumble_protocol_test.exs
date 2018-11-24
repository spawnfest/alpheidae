defmodule MumbleProtocolTest do
  use ExUnit.Case

  test "A message is encoded and decoded properly" do
    msg = MumbleProtocol.Version.new
    encoded = MumbleProtocol.encode(msg)
    {[decoded], <<>>} = MumbleProtocol.decode(encoded)
    assert msg == decoded
  end
end
