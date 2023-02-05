#ifndef _ROUTER_H
#define _ROUTER_H

#include "../ServerLib/ServerCommon.h"

#include "Packet.pb.h"

#include <functional>

namespace Router {
using PacketSender = std::function<void(const ConnectionPtr& conn, const PB::ForwardingPacket&)>;
void ForwardPacketToLS(uint32 user_conn_id, const PB::Packet& packet, const PacketSender& sender);
void ForwardPacketToRS(uint32 user_conn_id, const PB::Packet& packet, const PacketSender& sender);
};  // namespace Router

#endif  // _ROUTER_H
