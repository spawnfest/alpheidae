defmodule MumbleProtocolTest do
  use ExUnit.Case

  test "A message is encoded and decoded properly" do
    msg = MumbleProtocol.Version.new()
    encoded = MumbleProtocol.encode(msg)
    {[decoded], <<>>} = MumbleProtocol.decode(encoded)
    assert msg == decoded
  end

  test ".encode_varint: 7-bit number" do
    assert <<16>> == MumbleProtocol.encode_varint(16)
  end

  test ".encode_varint: 14-bit number" do
    assert <<129, 44>> == MumbleProtocol.encode_varint(300)
  end

  test ".encode_varint: 21-bit number" do
    assert <<209, 148, 107>> == MumbleProtocol.encode_varint(1_152_107)
  end

  test ".encode_varint: 28-bit number" do
    assert <<224, 32, 0, 19>> == MumbleProtocol.encode_varint(2_097_171)
  end

  test ".encode_varint: 32-bit number" do
    assert <<240, 16, 0, 0, 29>> == MumbleProtocol.encode_varint(268_435_485)
  end

  test ".encode_varint: 64-bit number" do
    assert <<244, 0, 0, 0, 1, 0, 0, 0, 29>> == MumbleProtocol.encode_varint(4_294_967_325)
  end
end
