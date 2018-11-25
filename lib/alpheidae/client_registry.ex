defmodule Alpheidae.ClientRegistry do
  use GenServer
  require Logger

  defmodule Client do
    @moduledoc false
    defstruct [
      :last_ping_at,
      :name,
      :session,
      :crypt_key,
      :client_nonce,
      :server_nonce,
      :channel_id,
      :permissions,
      :self_mute,
      :self_deaf
    ]
  end

  defmodule State do
    @moduledoc false
    defstruct []
  end

  @doc """
  Add a new client session to the registry and attempt to authenticate
  the client.
  """
  def register_session(client_pid, auth_message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:register_session, client_pid, auth_message})
  end

  @doc """
  Remove a client session from the registry.
  """
  def deregister(client_pid) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:deregister, client_pid})
  end

  @doc """
  Update the last time a client sent us a ping.
  """
  def record_ping(client_pid, ping) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:record_ping, client_pid, ping})
  end

  @doc """
  Get all users connected to the server as `MumbleProtocol.UserState` structs.
  """
  def all_users() do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:all_users})
  end

  @doc """
  Get the session id for a given client
  """
  def session_for(client_pid) do
    :erlang.phash2(client_pid)
  end

  @doc """
  Get the `MumbleProtocol.ServerSync` message sent to the client after sending,
  all of the channels and users.
  """
  def server_sync_for(client_pid) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:server_sync, client_pid})
  end

  @doc """
  Send a message to every client in the registry.
  """
  def broadcast(client_pid, message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:broadcast, client_pid, message})
  end

  @doc """
  Send a message to every client in the channel that the client is in.
  """
  def broadcast_to_channel(client_pid, message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:broadcast_to_channel, client_pid, message})
  end

  @doc """
  Update the registry state to match the sent client state
  """
  def update_client_state(client_pid, message) do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:update_client_state, client_pid, message})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :ordered_set])
    {:ok, %State{}}
  end

  def handle_call({:register_session, client_pid, auth_message}, _, state) do
    # TODO: Check username and password here
    # TODO: Don't hardcode this whenever we do udp
    user = %Client{
      name: auth_message.username,
      session: :erlang.phash2(client_pid),
      crypt_key: <<0::128>>,
      client_nonce: <<0::128>>,
      server_nonce: <<0::128>>,
      channel_id: 0,
      last_ping_at: :os.system_time(:millisecond),
      permissions: 0xC,
      self_mute: false,
      self_deaf: false
    }

    crypt_setup = MumbleProtocol.CryptSetup.new(
      key: user.crypt_key,
      client_nonce: user.client_nonce,
      server_nonce: user.server_nonce
    )

    :ets.insert(__MODULE__, {client_pid, user})
    user_state = client_to_user_state(user)
    broadcast_message(client_pid, user_state)

    {:reply, {:ok, crypt_setup}, state}
  end

  def handle_call({:deregister, client_pid}, _, state) do
    [{^client_pid, client}] = :ets.lookup(__MODULE__, client_pid)
    :ets.delete(__MODULE__, client_pid)
    remove_msg = MumbleProtocol.UserRemove.new(session: client.session)
    broadcast_message(client_pid, remove_msg)
    {:reply, :ok, state}
  end

  def handle_call({:record_ping, client_pid, ping_message}, _, state) do
    [{^client_pid, client}] = :ets.lookup(__MODULE__, client_pid)
    :ets.insert(
      __MODULE__,
      {client_pid, %{client | last_ping_at: :os.system_time(:millisecond) }}
    )
    server_ping = %MumbleProtocol.Ping{timestamp: ping_message.timestamp, good: 0}
    {:reply, {:ok, server_ping}, state}
  end

  def handle_call({:all_users}, _, state) do
    users = :ets.foldl(
      fn {_, t}, acc ->
        [client_to_user_state(t)] ++ acc
      end,
      [],
      __MODULE__
    )
    {:reply, users, state}
  end

  def handle_call({:server_sync, client_pid}, _, state) do
    [{^client_pid, client}] = :ets.lookup(__MODULE__, client_pid)

    sync = MumbleProtocol.ServerSync.new(
      session: client.session,
      max_bandwith: Application.get_env(:alpheidae, :max_bandwith),
      welcome_text: Application.get_env(:alpheidae, :welcome_text),
      permissions: client.permissions
    )

    {:reply, sync, state}
  end

  def handle_call({:broadcast, client_pid, message}, _, state) do
    broadcast_message(client_pid, message)
    {:reply, :ok, state}
  end

  def handle_call({:broadcast_to_channel, client_pid, message}, _, state) do
    [{^client_pid, client}] = :ets.lookup(__MODULE__, client_pid)
    fun = fn ({pid, c}, acc) -> if (client_pid == pid || c.channel_id != client.channel_id), do: acc, else: [pid] ++ acc end
    pids = :ets.foldl(fun, [], __MODULE__)
    for pid <- pids, do: send(pid, {:message, message})
    {:reply, :ok, state}
  end

  def handle_call({:update_client_state, client_pid, message}, _, state) do
    [{^client_pid, client}] = :ets.lookup(__MODULE__, client_pid)

    allowed_updates = %{
      self_mute: message.self_mute,
      self_deaf: message.self_deaf,
      channel_id: message.channel_id
    }

    new_client = Map.merge(
      client,
      allowed_updates,
      fn _, v1, v2 -> if v2 == nil, do: v1, else: v2 end
    )

    cond do
      message.session == client.session ->
        :ets.insert(__MODULE__, {client_pid, new_client})
        base_state = client_to_user_state(new_client)
        user_state = %{base_state| actor: client.session}
        broadcast_message(client_pid, user_state)
        send(client_pid, {:message, base_state})
      true ->
        [target] = client_by_session(message.session)
        denial = client_to_user_state(target)
        send(client_pid, {:message, denial})
    end

    {:reply, :ok, state}
  end

  def handle_call(_, _, state) do
    {:reply, :ok, state}
  end

  defp client_to_user_state(client) do
    MumbleProtocol.UserState.new(
      name: client.name,
      session: client.session,
      channel_id: client.channel_id,
      self_mute: client.self_mute,
      self_deaf: client.self_deaf
    )
  end

  defp broadcast_message(client_pid, message) do
    fun = fn ({pid, _}, acc) -> if (client_pid == pid), do: acc, else: [pid] ++ acc end
    pids = :ets.foldl(fun, [], __MODULE__)
    for pid <- pids, do: send(pid, {:message, message})
  end

  defp client_by_session(session) do
    fun = fn ({_, c}, acc) -> if (c.session == session), do: [c] ++ acc, else: acc end
    :ets.foldl(fun, [], __MODULE__)
  end
end
