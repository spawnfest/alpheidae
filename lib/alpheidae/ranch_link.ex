defmodule Alpheidae.RanchLink do
  @moduledoc """
  Wrapper module to get ranch into Elixir's supervisor.
  """

  @doc """
  Starts the ranch listener, listening on the port set in the application environment.
  """
  def start_link do
    options = Application.get_env(:alpheidae, :socket_options)

    {:ok, _} =
      :ranch.start_listener(:alpheidae_listener, 100, :ranch_ssl, options, Alpheidae.Protocol, [])
  end
end
