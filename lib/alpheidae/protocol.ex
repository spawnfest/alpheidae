defmodule Alpheidae.Protocol do
  require Logger

  @behaviour :ranch_protocol

  @moduledoc """
  Alpheidae.Protocol implements a ranch protocol translating Mumble's wire protocol
  into usable messages.
  """
  def start_link(ref, socket, transport, _opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  @doc """
  Whenever a `Alpheidae.Protocol` process is started via start_link/4, this function is
  called to initialize it.
  """
  def init(ref, socket, transport) do
    :ok = :ranch.accept_ack(ref)
    :ok = Alpheidae.VoiceServer.start_monitor()

    transport.setopts(socket, [active: :once])
    loop(socket, transport, <<>>)
  end

  defp loop(socket, transport, old_data) do
    receive do
      {:ssl, ^socket, new_data} ->
        {messages, next_data} = MumbleProtocol.decode(old_data <> new_data)
        for message <- messages, do: handle_message(socket, transport, message)
        transport.setopts(socket, [active: :once])
        loop(socket, transport, next_data)
      {:ssl_closed, ^socket} ->
        :ok
      {:message, message} ->
        packet = MumbleProtocol.encode(message)
        transport.send(socket, packet)
        loop(socket, transport, old_data)
      any ->
        IO.puts("Got unhandled message #{inspect any, pretty: true}")
        loop(socket, transport, old_data)
    end
  end

  defp handle_message(socket, transport, message) do
    replies = Alpheidae.VoiceServer.dispatch(message)

    for reply <- replies do
      packet = MumbleProtocol.encode(reply)
      transport.send(socket, packet)

      case reply do
        %MumbleProtocol.Reject{} ->
          :ok = transport.close(socket)
        _any ->
          :ok
      end
    end
  end
end
