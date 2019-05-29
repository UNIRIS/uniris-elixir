defmodule Gossip.Server do
  use Task
  require Logger

  @default_tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  def start_link(state) do
    Logger.debug("Gossip server is running on port #{state[:port]}")
    Task.start_link(__MODULE__, :run, [state])
  end

  def run(state) do
    {:ok, socket} = :gen_tcp.listen(state[:port], @default_tcp_opts)
    accept_loop(state[:local_peer], socket)
  end

  def accept_loop(local_peer = %Gossip.Peer{}, socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    Task.Supervisor.start_child(Gossip.Request.Supervisor, fn ->
      handle_request(conn, local_peer)
    end)
    accept_loop(local_peer, socket)
  end

  defp handle_request(socket, local_peer) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, <<msg_id::8, data::binary>>} when msg_id == 1 ->
        Logger.debug("SYN request received")
        received = :erlang.binary_to_term(data)
        {new, refresh} = handle_syn_request(received)

        # Reply the SYN-ACK
        response = :erlang.term_to_binary(new: new, refresh: refresh)
        :gen_tcp.send(socket, <<2>> <> response)

      {:ok, <<msg_id::8, data::binary>>} when msg_id == 3 ->
        Logger.debug("ACK request received")
        handle_ack_request(:erlang.binary_to_term(data), local_peer)
    end
  end

  defp handle_syn_request(received_peers) when is_list(received_peers) do
    discovered = Gossip.Storage.list_discovered_peers()

    new =
      Enum.filter(received_peers, fn p ->
        !Enum.any?(discovered, fn d -> p.public_key == d.public_key end)
      end)

    refresh =
      Enum.filter(received_peers, fn p ->
        existing = Enum.find(discovered, fn r -> p.public_key == r.public_key end)

        if existing do
          Gossip.Peer.more_recent_than(p, existing)
        end
      end)

    {new, refresh}
  end

  defp handle_ack_request(new_peers, local_peer = %Gossip.Peer{}) when is_list(new_peers) do
    new_peers
    |> Enum.filter(fn p -> p.public_key != local_peer.public_key end)
    |> Enum.each(fn p -> Gossip.Storage.add_discovered_peer(p) end)
  end
end
