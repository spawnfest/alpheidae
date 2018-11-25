defmodule Alpheidae.ChannelRegistry do
  use GenServer
  require Logger

  defmodule Channel do
    @moduledoc false
    defstruct [
      :channel_id,
      :name
    ]
  end

  #root_channel = MumbleProtocol.ChannelState.new(
    #  channel_id: 0,
    #  name: "Tmp Root Ch"
    #)


  defmodule State do
    @moduledoc false
    defstruct []
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    root = %Channel{
      channel_id: 0,
      name: "root"
    }
    :ets.new(__MODULE__, [:named_table, :ordered_set])
    :ets.insert(__MODULE__, {0, root})
    {:ok, %State{}}
  end

  def handle_info(_, state) do
    {:reply, :ok, state}
  end

  @doc """
  Get all channels connected to the server as `MumbleProtocol.ChannelState` structs.
  """
  def all_channels() do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:all_channels})
  end

  def handle_call({:all_channels}, _, state) do
    channels = :ets.foldl(
      fn {_, t}, acc ->
        [channel_to_channel_state(t)] ++ acc
      end,
      [],
      __MODULE__
    )
    {:reply, channels, state}
  end

  defp channel_to_channel_state(channel) do
    MumbleProtocol.ChannelState.new(
      name: channel.name,
      channel_id: channel.channel_id
    )
  end
end
