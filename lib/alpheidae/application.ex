defmodule Alpheidae.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Alpheidae.ClientRegistry, [name: Alpheidae.ClientRegistry]},
      {Alpheidae.VoiceServer, [name: Alpheidae.VoiceServer]},
      worker(Alpheidae.RanchLink, [])
    ]

    opts = [strategy: :one_for_one, name: Alpheidae.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
