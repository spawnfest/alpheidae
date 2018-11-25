defmodule Alpheidae.ChannelRegistry do
  use GenServer
  require Logger

  defmodule Channel do
    @moduledoc false
    defstruct [
      :channel_id,
      :name,
      :parent_channel_id,
      :description,
      :position
    ]
  end

  defmodule State do
    @moduledoc false
    defstruct []
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :ordered_set])

    root = %Channel{
      channel_id: 0,
      name: "Root",
      parent_channel_id: -1,
      position: 0
    }
    :ets.insert(__MODULE__, {0, root})

    channels = Application.get_env(:alpheidae, :channels)
    for ch <- channels do
      base = %Channel{
        channel_id: :os.system_time(:seconds),
        parent_channel_id: 0,
        position: 1,
      }

      rec = Map.merge(base, ch)
      :ets.insert(__MODULE__, {rec.channel_id, rec})
    end

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

  @doc """
  Get all channels connected to the server as `MumbleProtocol.ChannelState` structs.

  This is different from `all_channels/0` in one critical regard: it includes the channel linking information.

  This is done because clients need to know all available channels before knowing about their linkage.
  """
  def all_channels_linked() do
    server_pid = :erlang.whereis(__MODULE__)
    GenServer.call(server_pid, {:all_channels_linked})
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

  def handle_call({:all_channels_linked}, _, state) do
    channels = :ets.foldl(
      fn {_, t}, acc ->
        [channel_to_channel_state_linked(t)] ++ acc
      end,
      [],
      __MODULE__
    )
    {:reply, channels, state}
  end

  defp channel_to_channel_state(channel) do
    MumbleProtocol.ChannelState.new(
      name: channel.name,
      channel_id: channel.channel_id,
      description: channel.description
    )
  end
  defp channel_to_channel_state_linked(channel) do
    MumbleProtocol.ChannelState.new(
      name: channel.name,
      channel_id: channel.channel_id,
      parent: channel.parent_channel_id,
      description: channel.description,
      position: channel.position
    )
  end
end
