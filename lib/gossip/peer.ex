defmodule Gossip.Peer do

  @enforce_keys [:ip, :port, :public_key, :heartbeat_gen_time, :elapsed_heartbeats]
  defstruct [:ip, :port, :public_key, :heartbeat_gen_time, :elapsed_heartbeats, :latitude]

  def new_local(ip, port, public_key)
      when is_integer(port)
      when is_binary(public_key) do
    case :inet.parse_address(ip) do
      {:ok, addr} ->
        %Gossip.Peer{
          ip: addr,
          port: port,
          public_key: public_key,
          heartbeat_gen_time: System.system_time(:millisecond),
          elapsed_heartbeats: 0,
        }
    end
  end

  def new_digest(ip, port, public_key)
      when is_integer(port)
      when is_binary(public_key) do
    case :inet.parse_address(ip) do
      {:ok, addr} ->
        %Gossip.Peer{
          ip: addr,
          port: port,
          public_key: public_key,
          heartbeat_gen_time: 0,
          elapsed_heartbeats: 0
        }
    end
  end

  def refresh(peer = %Gossip.Peer{}) do
    refresh_elasped_hearbeats(peer)
  end

  def more_recent_than(from = %Gossip.Peer{}, to = %Gossip.Peer{}) do
    cond do
      from.heartbeat_gen_time > to.heartbeat_gen_time ->
        true

      from.heartbeat_gen_time == to.heartbeat_gen_time ->
        cond do
          from.elapsed_heartbeats == to.elapsed_heartbeats -> false
          from.elapsed_heartbeats > to.elapsed_heartbeats -> true
          true -> false
        end

      true ->
        false
    end
  end

  defp refresh_elasped_hearbeats(peer = %Gossip.Peer{}) do
    Map.put(
      peer,
      :elapsed_heartbeats,
      System.system_time(:millisecond) - peer.heartbeat_gen_time
    )
  end
end
