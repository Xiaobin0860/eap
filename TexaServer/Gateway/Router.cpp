#include "Router.h"

#include "GateUser.h"

namespace Router {

void ForwardPacketToLS(uint32 user_conn_id, const PB::Packet& packet, const PacketSender& sender)
{
    auto ls = GetGateUserManager().GetLogicServerFromUserConnId(user_conn_id);
    if (ls == 0) {
        return;
    }

    PB::ForwardingPacket pkt;
    pkt.set_command(packet.command());
    pkt.set_user_conn_id(user_conn_id);

    auto user_id = GetGateUserManager().GetUserId(user_conn_id);
    pkt.set_user_id(user_id);

    pkt.set_serialized(packet.serialized());
    sender(ls, pkt);
}

void ForwardPacketToRS(uint32 user_conn_id, const PB::Packet& packet, const PacketSender& sender)
{
    auto ls = GetGateUserManager().GetRecordServer();
    if (ls == 0) {
        return;
    }

    PB::ForwardingPacket pkt;
    pkt.set_command(packet.command());
    pkt.set_user_conn_id(user_conn_id);

    auto user_id = GetGateUserManager().GetUserId(user_conn_id);
    pkt.set_user_id(user_id);

    pkt.set_serialized(packet.serialized());
    sender(ls->GetConn(), pkt);
}

}  // namespace Router
