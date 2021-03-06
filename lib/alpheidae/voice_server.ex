defmodule Alpheidae.VoiceServer do
  use GenServer
  require Logger
  alias Alpheidae.ClientRegistry, as: Client
  alias Alpheidae.ChannelRegistry, as: Channel

  @doc """
  Process a message from the mumble wire protocol
  """
  def dispatch(message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:dispatch, message})
  end

  defmodule State do
    @moduledoc false
    defstruct []
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    {:ok, %State{}}
  end

  def handle_info(_, state) do
    {:reply, :ok, state}
  end

  def handle_call(
        {:dispatch, %MumbleProtocol.Authenticate{} = auth},
        {from_pid, _from_ref},
        state
      ) do
    {:ok, crypt_setup} = Client.register_session(from_pid, auth)

    channels = Channel.all_channels()
    channels_linked = Channel.all_channels_linked()
    users = Client.all_users()
    server_sync = Client.server_sync_for(from_pid)

    payload = [crypt_setup] ++ channels ++ channels_linked ++ users ++ [server_sync]

    {:reply, payload, state}
  end

  def handle_call({:dispatch, %MumbleProtocol.PermissionQuery{}}, _, state) do
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.Version{}}, _, state) do
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.Ping{} = client_ping}, {from_pid, _from_ref}, state) do
    {:ok, server_ping} = Client.record_ping(from_pid, client_ping)
    {:reply, [server_ping], state}
  end

  def handle_call(
        {:dispatch, %MumbleProtocol.UserState{} = user_state},
        {from_pid, _from_ref},
        state
      ) do
    Client.update_client_state(from_pid, user_state)
    {:reply, [user_state], state}
  end

  def handle_call(
        {:dispatch, %MumbleProtocol.VoicePacket{} = client_output},
        {from_pid, _from_self},
        state
      ) do
    session = Client.session_for(from_pid)
    client_input = %{client_output | session: session}
    Client.broadcast_to_channel(from_pid, client_input)
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.ACL{} = acl}, {from_pid, _from_self}, state) do
    reply = MumbleProtocol.ACL.new(channel_id: acl.channel_id)
    send(from_pid, {:message, reply})
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.ChannelState{}}, {from_pid, _from_self}, state) do
    session = Client.session_for(from_pid)
    reply = MumbleProtocol.PermissionDenied.new(deny_type: 11, session: session)
    send(from_pid, {:message, reply})
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.ChannelRemove{}}, {from_pid, _from_self}, state) do
    session = Client.session_for(from_pid)
    reply = MumbleProtocol.PermissionDenied.new(deny_type: 11, session: session)
    send(from_pid, {:message, reply})
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.UserStats{} = stats}, {from_pid, _from_self}, state) do
    send(from_pid, {:message, stats})
    {:reply, [], state}
  end

  def handle_call(
        {:dispatch,
         %MumbleProtocol.TextMessage{channel_id: target_channels, session: []} = text_message},
        {from_pid, _from_self},
        state
      )
      when is_list(target_channels) and length(target_channels) > 0 do
    session = Client.session_for(from_pid)
    msg = %{text_message | actor: session}
    Client.broadcast_to_channel(from_pid, msg)
    {:reply, [], state}
  end

  def handle_call(
        {:dispatch,
         %MumbleProtocol.TextMessage{channel_id: [], session: target_sessions} = text_message},
        {from_pid, _from_self},
        state
      )
      when is_list(target_sessions) and length(target_sessions) > 0 do
    session = Client.session_for(from_pid)
    msg = %{text_message | actor: session}
    Client.broadcast_to_sessions(target_sessions, msg)
    {:reply, [], state}
  end

  def handle_call({:dispatch, %MumbleProtocol.TextMessage{}}, {_from_pid, _from_self}, state) do
    {:reply, [], state}
  end

  def handle_call({:dispatch, message}, {from_pid, _from_ref}, state) do
    Logger.debug("Unknown Message from `#{inspect(from_pid)}`: #{inspect(message)}")
    reply = MumbleProtocol.Reject.new(type: 0, reason: "Unknown Message")
    {:reply, [reply], state}
  end
end
