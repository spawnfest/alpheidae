defmodule MumbleProtocol do
  use Protobuf, from: Path.expand("../proto/mumble.proto", __DIR__)
end
