defmodule Gossip.Runner do
  use GenServer
  require Logger

  @default_tcp_opts [:binary, {:active, false}]

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    schedule(state[:cycle_milliseconds])
    {:ok, state}
  end

  def handle_info(:new_cycle, state) do
    schedule(state[:cycle_milliseconds])

    # Refresh the local peer information (heartbeat state, app state)
    local_peer = Gossip.Peer.refresh(state[:local_peer])

    Task.Supervisor.start_child(Gossip.Cycle.Supervisor, fn ->
      start_cycle(state[:seeds], local_peer)
    end)

    {:noreply, Keyword.update!(state, :local_peer, fn _ -> local_peer end)}
  end

  defp schedule(cycle_milliseconds) when is_integer(cycle_milliseconds) do
    Process.send_after(self(), :new_cycle, cycle_milliseconds)
  end

  defp start_cycle(seeds, local_peer) when is_list(seeds) do
    # Query the known peers
    discovered = Gossip.Storage.list_discovered_peers()
    unreachables = Gossip.Storage.list_unreachables_peers()

    # Include ourself to be discovered by others
    peers = discovered ++ [local_peer]

    Task.Supervisor.start_child(Gossip.Cycle.Supervisor, fn ->
      start_round(seeds, peers, local_peer)
    end)

    reachables =
      Enum.filter(discovered, fn p ->
        !Enum.any?(unreachables, fn ur -> ur.public_key == p.public_key end)
      end)

    if length(reachables) > 0 do
      Task.Supervisor.start_child(Gossip.Cycle.Supervisor, fn ->
        start_round(reachables, peers, local_peer)
      end)
    end

    if length(unreachables) > 0 do
      Task.Supervisor.start_child(Gossip.Cycle.Supervisor, fn ->
        start_round(unreachables, peers, local_peer)
      end)
    end

    {:noreply}
  end

  defp start_round(peer_references, peers_list, local_peer = %Gossip.Peer{})
       when is_list(peer_references)
       when is_list(peers_list) do
    with {:ok, remote_peer} <- get_remote_peer(peer_references, local_peer) do
      gossip(local_peer, peers_list, remote_peer)
    end
  end

  defp get_remote_peer(peer_list, local_peer) do
    peers = Enum.filter(peer_list, fn p -> p.public_key != local_peer.public_key end)

    if length(peers) > 0 do
      {:ok, Enum.random(peers)}
    end
  end

  defp gossip(local_peer, discovered_peers, remote_peer = %Gossip.Peer{})
       when is_list(discovered_peers) do
    # Send the SYN request by sending the discovered peers digest
    case send_syn_request(remote_peer, discovered_peers) do
      {:ok, new, refresh} ->
        Gossip.Storage.delete_unreachable_peer(remote_peer)

        # Add the refresh version of the peers (excluding ourself)
        refresh
        |> Enum.filter(fn p -> p.public_key != local_peer.public_key end)
        |> Enum.each(fn p -> Gossip.Storage.add_discovered_peer(p) end)

        # Send the ACK reply with the details of the requested peers
        case send_ack_request(remote_peer, new) do
          :unreachable ->
            Gossip.Storage.add_unreachable_peer(remote_peer)

          :ok ->
            Gossip.Storage.delete_unreachable_peer(remote_peer)
        end

      :unreachable ->
        Gossip.Storage.add_unreachable_peer(remote_peer)
    end
  end

  defp send_syn_request(remote_peer = %Gossip.Peer{}, peers) when is_list(peers) do
    case :gen_tcp.connect(remote_peer.ip, remote_peer.port, @default_tcp_opts) do
      {:ok, socket} ->
        data = <<1>> <> :erlang.term_to_binary(peers)
        :gen_tcp.send(socket, data)

        case :gen_tcp.recv(socket, 0) do
          # Catch the SYN-ACK
          {:ok, <<msg_id::8, data::binary>>} when msg_id == 2 ->
            Logger.debug("SYN-ACK response received")
            response = :erlang.binary_to_term(data)
            :gen_tcp.close(socket)
            {:ok, response[:new], response[:refresh]}
        end

      _ ->
        :unreachable
    end
  end

  defp send_ack_request(remote_peer = %Gossip.Peer{}, new_peers) when is_list(new_peers) do
    case :gen_tcp.connect(remote_peer.ip, remote_peer.port, @default_tcp_opts) do
      {:ok, socket} ->
        # TODO: get details about the requested peers such as AppState
        data = <<3>> <> :erlang.term_to_binary(new_peers)
        :gen_tcp.send(socket, data)
        :gen_tcp.close(socket)

      _ ->
        :unreachable
    end
  end
end
