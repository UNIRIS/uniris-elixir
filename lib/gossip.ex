defmodule Gossip do
  use Application

  def start(_type, _args) do
    seeds =
      Enum.map(Application.get_env(:gossip, :seeds), fn p ->
        Gossip.Peer.new_digest(p.ip, p.port, p.public_key)
      end)

    cycle_milliseconds = Application.get_env(:gossip, :cycle_milliseconds)
    public_key = Application.get_env(:gossip, :public_key)
    port = Application.get_env(:gossip, :port)

    local_peer = init_peer(port, public_key)

    children = [
      
      Gossip.Storage,

      {Task.Supervisor, name: Gossip.Request.Supervisor},
      {Gossip.Server, [port: port, local_peer: local_peer]},

      {Task.Supervisor, name: Gossip.Cycle.Supervisor},
      {Gossip.Runner,
       [
         seeds: seeds,
         cycle_milliseconds: cycle_milliseconds,
         public_key: public_key,
         port: port,
         local_peer: local_peer
       ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp init_peer(port, public_key) do
    Gossip.Peer.new_local(
      # TODO: retrieve the IP from conf or net iface
      '127.0.0.1',
      port,
      public_key
    )
  end
end
