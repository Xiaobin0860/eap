#ifndef _GATEWAY_H
#define _GATEWAY_H

#include "../ServerLib/ServerCommon.h"
#include "../ServerLib/TcpConnection.h"

#include "Packet.pb.h"

#include "GateUser.h"

#define IS_DEBUG_VER 1

struct GameInstanceDesc;
class Gateway {
public:
    Gateway();

public:
    void Run(const std::string& ip, const std::string& port, int pool_size);

public:
    bool CheckServerDisconnect(uint32 user_conn_id);
    void UserLeaveGame(uint32 user_conn_id);
    void UserDisconnect(uint32 user_conn_id);

    void SendGameList(const ConnectionPtr& conn, const std::string& game_name);

private:
    // game server operations
    template <typename T>
    void SendRawPacket(const ConnectionPtr& conn, const T& packet);
    void SendPacket(uint32 conn_id, Protocol::ClientGateProtocol cmd, const std::string& pkt);
    template <typename T>
    void SendPacket(const ConnectionPtr& conn, Protocol::ClientGateProtocol cmd, const T& pkt);
    template <typename T>
    void ForwardPacket(const ConnectionPtr& conn, Protocol::ClientGateProtocol cmd, uint32 user_conn_id, const T& pkt);

private:
    // handler
    void Dispatch(const ConnectionPtr& conn, const uint8* buf, uint32 len);

    // Client packet
    bool PreHandleClientPacket(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleClientPacket(const ConnectionPtr& conn, const PB::Packet& packet);

    void HandleHeartBeat(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleServerLogin(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleClientLogin(const ConnectionPtr& conn, const PB::Packet& packet);

    void HandleUserListRequest(const ConnectionPtr& conn, const PB::Packet& packet);

    void HandleAddFriend(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleAddFriendConfirm(const ConnectionPtr& conn, const PB::Packet& packet);

    void HandleClientGetInstanceList(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleLookTable(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleClientEnterGame(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleQuickClientEnterGame(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleClientLeaveGame(const ConnectionPtr& conn, const PB::Packet& packet);
    void HandleClientGetInfo(const ConnectionPtr& conn, const PB::Packet& packet);

    // Server packet
    bool PreHandleServerPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);
    void HandleForwardingPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);
    void RealForwardingPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);

    void HandleClientLoginResponse(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);
    void HandleGameInstanceList(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);
    void HandleSaveData(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);
    void HandleSaveDataResponse(const ConnectionPtr& conn, const PB::ForwardingPacket& packet);

private:
    void PlayerLookTable(const ConnectionPtr& conn, ClientGate::LookTable& request);
    void PlayerEnterRoom(const ConnectionPtr& conn, ClientGate::EnterGameRequest& request);

    GateUserPtr GetLogicServerAndRoomInfo(const ConnectionPtr& conn, const std::string& name, uint32 room_id,
                                          GameInstanceDesc& info);

private:
    // callbacks
    FuncOnAccept        GetAcceptCallBack();
    ConnectionCallBacks GetCallBacks();
    void                OnAccept(const ConnectionPtr& conn);
    void                OnConnected(const ConnectionPtr& conn, bool success);
    uint32              OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len);
    void                OnWrite(const ConnectionPtr& conn, uint32 len);
    void                OnDisconnect(const ConnectionPtr& conn);
};

template <typename T>
inline void Gateway::SendRawPacket(const ConnectionPtr& conn, const T& packet)
{
    uint32 len = packet.ByteSize();

    FastBuf<uint8> buf(len + 4);
    packet.SerializeToArray(buf.buf + 4, len);
    memcpy(buf.buf, &len, 4);
    conn->Send(buf.buf, len + 4);
}
inline void Gateway::SendPacket(uint32 conn_id, Protocol::ClientGateProtocol cmd, const std::string& pkt)
{
    auto user = GetGateUserManager().GetUser(conn_id);
    if (user == 0) {
        return;
    }
    PB::Packet packet;
    packet.set_command(cmd);
    packet.set_serialized(pkt);
    SendRawPacket(user->GetConn(), packet);
}
template <typename T>
void Gateway::SendPacket(const ConnectionPtr& conn, Protocol::ClientGateProtocol cmd, const T& pkt)
{
    PB::Packet packet;
    packet.set_command(cmd);

    pkt.SerializeToString(packet.mutable_serialized());
    SendRawPacket(conn, packet);
}
template <typename T>
void Gateway::ForwardPacket(const ConnectionPtr& conn, Protocol::ClientGateProtocol cmd, uint32 user_conn_id,
                            const T& pkt)
{
    PB::ForwardingPacket packet;
    packet.set_command(cmd);
    packet.set_user_conn_id(user_conn_id);
    auto user_id = GetGateUserManager().GetUserId(user_conn_id);
    packet.set_user_id(user_id);

    pkt.SerializeToString(packet.mutable_serialized());
    uint32 len = packet.ByteSize();

    FastBuf<uint8> buf(len + 4);
    packet.SerializeToArray(buf.buf + 4, len);
    memcpy(buf.buf, &len, 4);
    conn->Send(buf.buf, len + 4);
}

inline FuncOnAccept Gateway::GetAcceptCallBack()
{
    return std::bind(&Gateway::OnAccept, this, std::placeholders::_1);
}

inline ConnectionCallBacks Gateway::GetCallBacks()
{
    ConnectionCallBacks cb = {
        std::bind(&Gateway::OnConnected, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Gateway::OnRead, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3),
        std::bind(&Gateway::OnWrite, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Gateway::OnDisconnect, this, std::placeholders::_1),
    };
    return cb;
}

#endif  // _GATEWAY_H
