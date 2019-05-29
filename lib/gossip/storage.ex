defmodule Gossip.Storage do
  use Agent
  require Logger

  def start_link(_opts) do
    Agent.start_link(
      fn ->
        %{
          discovered_peers: %{},
          unreachable_peers: %{}
        }
      end,
      name: __MODULE__
    )
  end

  def list_discovered_peers() do
    Agent.get(__MODULE__, fn db -> Map.values(db.discovered_peers) end)
  end

  def list_unreachables_peers() do
    Agent.get(__MODULE__, fn db -> Map.values(db.unreachable_peers) end)
  end

  def add_discovered_peer(peer = %Gossip.Peer{}) do
    Agent.update(__MODULE__, fn db ->
      Logger.debug("New discovered peer stored")
      new_discovered = Map.put(db.discovered_peers, peer.public_key, peer)
      Map.put(db, :discovered_peers, new_discovered)
    end)
  end

  def add_unreachable_peer(peer = %Gossip.Peer{}) do
    Agent.update(__MODULE__, fn db ->
      Logger.debug("Unreachable peer stored")
      new_unreachables = Map.put(db.unreachable_peers, peer.public_key, peer)
      Map.put(db, :unreachable_peers, new_unreachables)
    end)
  end

  def delete_unreachable_peer(peer = %Gossip.Peer{}) do
    Agent.update(__MODULE__, fn db ->
      if Map.has_key?(db.unreachable_peers, peer.public_key) do
        Logger.debug("Remove unreachable peer")
      end

      Map.put(db, :unreachable_peers, Map.delete(db.unreachable_peers, peer.public_key))
    end)
  end
end
