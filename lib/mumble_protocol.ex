defmodule MumbleProtocol do
  use Protobuf, from: Path.expand("../proto/mumble.proto", __DIR__)
  use Bitwise

  @message_types [
    MumbleProtocol.Version,
    MumbleProtocol.UDPTunnel,
    MumbleProtocol.Authenticate,
    MumbleProtocol.Ping,
    MumbleProtocol.Reject,
    MumbleProtocol.ServerSync,
    MumbleProtocol.ChannelRemove,
    MumbleProtocol.ChannelState,
    MumbleProtocol.UserRemove,
    MumbleProtocol.UserState,
    MumbleProtocol.BanList,
    MumbleProtocol.TextMessage,
    MumbleProtocol.PermissionDenied,
    MumbleProtocol.ACL,
    MumbleProtocol.QueryUsers,
    MumbleProtocol.CryptSetup,
    MumbleProtocol.ContextActionModify,
    MumbleProtocol.ContextAction,
    MumbleProtocol.UserList,
    MumbleProtocol.VoiceTarget,
    MumbleProtocol.PermissionQuery,
    MumbleProtocol.CodecVersion,
    MumbleProtocol.UserStats,
    MumbleProtocol.RequestBlob,
    MumbleProtocol.ServerConfig,
    MumbleProtocol.SuggestConfig
  ]

  defmodule VoicePacket do
    @moduledoc false
    defstruct [:data, :target, :type]
  end

  @doc """
  Extracts and parses any protobuf messages in the given binary,
  returning a list of the decoded messages and all of the unprocessed
  data
  """
  def decode(data) do
    decode(data, [])
  end

  defp decode(<<type :: signed-big-integer-size(16), length :: signed-big-integer-size(32), data :: binary>>, msgs) when byte_size(data) >= length do
    {message_binary, next_data} = Binary.split_at(data, length)
    message = decode_one(type, message_binary)
    decode(next_data, [message|msgs])
  end

  defp decode(data, msgs) do
    {Enum.reverse(msgs), data}
  end

  # Handle the voice packets differently than the regular ones
  defp decode_one(1, data) do
    <<header :: signed-big-integer-size(8), _ :: binary>> = data
    target = band(0b00011111, header)
    type = band(0b11100000, header)
    %MumbleProtocol.VoicePacket{data: data, target: target, type: type}
  end

  defp decode_one(type, data) do
    Enum.fetch!(@message_types, type).decode(data)
  end

  @doc """
  Encodes a struct as binary with the approprate header for the mumble client
  """
  # Hande voice differently
  def encode(%MumbleProtocol.VoicePacket{} = struct) do
    <<1 :: signed-big-integer-size(16), byte_size(struct.data) :: signed-big-integer-size(32)>> <> struct.data
  end

  def encode(struct) do
    type = struct.__struct__
    type_number = Enum.find_index(@message_types, fn a -> a == type end)
    binary = type.encode(struct)
    <<type_number :: signed-big-integer-size(16), byte_size(binary) :: signed-big-integer-size(32)>> <> binary
  end
end
