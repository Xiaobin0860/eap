#ifndef _SENDPACKET_H
#define _SENDPACKET_H

#include "Packet.pb.h"
#include "Protocol.pb.h"


template <typename C, typename T>
void SendPacket(const C& c, const T& packet)
{
    uint32 len = packet.ByteSize();

    FastBuf<uint8> buf(len + 4);
    packet.SerializeToArray(buf.buf + 4, len);
    memcpy(buf.buf, &len, 4);
    c->Send(buf.buf, len + 4);
}
template <typename S, typename C, typename T>
void SendPacket(const S& s, unsigned conn_id, const std::string& uuid, C cmd, const T& packet)
{
    PB::ForwardingPacket pkt;
    pkt.set_command(cmd);
    pkt.set_user_conn_id(conn_id);
    pkt.set_user_id(uuid);
    packet.SerializeToString(pkt.mutable_serialized());

    SendPacket(s, pkt);
}

template <typename S, typename C, typename T>
void SendPacket(const S& s, C cmd, const T& packet)
{
    PB::Packet pkt;
    pkt.set_command(cmd);
    packet.SerializeToString(pkt.mutable_serialized());

    SendPacket(s, pkt);
}

#endif  // _SENDPACKET_H
