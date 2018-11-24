defmodule Alpheidae.VoiceServer do
  use GenServer

  require Logger

  @doc """
  Treat the calling process as a connecting Mumble client and set up the
  appropriate monitors. This sould be called before attempting to dispatch any
  messages sent by a client.
  """
  def start_monitor() do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:start_monitor})
  end

  @doc """
  Process a message from the mumble wire protocol
  """
  def dispatch(message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:dispatch, message})
  end

  defmodule State do
    @moduledoc false
    defstruct clients: %{}

    def client_for(state, pid) do
      Map.get(state.clients, pid)
    end

    def update_client(state, pid, client) do
      new_clients = Map.put(state.clients, pid, client)
      %{state | clients: new_clients}
    end
  end

  defmodule Client do
    @moduledoc false
    defstruct [:last_ping_at, :username]
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc false
  def init(_) do
    {:ok, %State{}}
  end

  @doc false
  def handle_info(_, state) do
    {:noreply, state}
  end

  @doc false
  def handle_call({:start_monitor}, {from_pid, _from_ref}, state) do
    # TODO: Move this to a helper function and get os properties
    version = MumbleProtocol.Version.new(
      os: "Unknown",
      os_version: "Unknown",
      release: "1.2.19",
      version: 66067
    )

    clients = Map.put(
      state.clients,
      from_pid,
      %Client{last_ping_at: :os.system_time(:millisecond)}
    )

    send(from_pid, {:message, version})
    {:reply, :ok, %{state | clients: clients}}
  end

  def handle_call({:dispatch, %MumbleProtocol.Authenticate{} = auth}, {from_pid, _from_ref}, state) do
    session = :erlang.phash2(from_pid)
    # TODO: Check username and password here
    # TODO: Don't hardcode this whenever we do udp
    crypt_setup = MumbleProtocol.CryptSetup.new(
      key: <<0::128>>,
      client_nonce: <<0::128>>,
      server_nonce: <<0::128>>
    )

    root_channel = MumbleProtocol.ChannelState.new(
      channel_id: 0,
      name: "Tmp Root Ch",
    )

    user = MumbleProtocol.UserState.new(name: auth.username, channel_id: 0, session: session)
    server_sync = MumbleProtocol.ServerSync.new(session: session, max_bandwith: 8192, welcome_text: "Hello!", permissions: 0xf07ff)

    {:reply, [crypt_setup, root_channel, user, server_sync], state}
  end

  @doc false
  def handle_call({:dispatch, %MumbleProtocol.PermissionQuery{}}, {from_pid, _from_ref}, state) do
    {:reply, [], state}
  end

  @doc false
  def handle_call({:dispatch, %MumbleProtocol.Version{}}, {from_pid, _from_ref}, state) do
    {:reply, [], state}
  end

  @doc false
  def handle_call({:dispatch, %MumbleProtocol.Ping{} = client_ping}, {from_pid, _from_ref}, state) do
    client = State.client_for(state, from_pid)
    # TODO: Keep track of when the last ping from each client was
    server_ping = %MumbleProtocol.Ping{timestamp: client_ping.timestamp, good: 0}
    next_state = State.update_client(state, from_pid, client)
    {:reply, [server_ping], next_state}
  end

  @doc false
  def handle_call({:dispatch, message}, {from_pid, _from_ref}, state) do
    Logger.debug("Unknown Message from `#{inspect from_pid}`: #{inspect message}")
    reply = MumbleProtocol.Reject.new(type: 0, reason: "Unknown Message")
    {:reply, [reply], state}
  end
end
