#include "Gateway.h"

#include "../ServerLib/TcpConnection.h"
#include "../ServerLib/TcpServer.h"


#include "Packet.pb.h"

#include "GameMgr.h"
#include "GateUser.h"


Gateway::Gateway()
{
#if IS_DEBUG_VER
    // GetGameMgr().AddGame("TexasPoker", 10, { -1, -1, "5,10,5,1",   0, 9, 100, 2000,  1000 });
    // GetGameMgr().AddGame("TexasPoker", 10, { -1, -1, "10,20,10,1", 0, 9, 200, 4000, 2000 });
    // GetGameMgr().AddGame("TexasPoker", 10, { -1, -1, "25,50,25,1", 0, 9, 500, 10000, 5000 });
#endif  // IS_DEBUG_VER
}

void Gateway::Run(const std::string& ip, const std::string& port, int pool_size)
{
    server.reset(new TcpServer(ip, port, pool_size, GetAcceptCallBack()));
    server->SetCallBacks(GetCallBacks());

    server->Run();
}

void Gateway::Dispatch(const ConnectionPtr& conn, const uint8* buf, uint32 len)
{
    // packet from LS
    GateUserPtr ls = GetGateUserManager().GetLogicServer(conn->GetId());
    GateUserPtr rs = GetGateUserManager().GetRecordServer(conn->GetId());
    if (ls != 0 || rs != 0) {
        PB::ForwardingPacket packet;
        if (!packet.ParseFromArray(buf, len)) {
            return;
        }
        HandleForwardingPacket(conn, packet);
        return;
    }

    // raw packet
    PB::Packet packet;
    if (!packet.ParseFromArray(buf, len)) {
        return;
    }
    HandleClientPacket(conn, packet);
}

void Gateway::OnAccept(const ConnectionPtr& conn)
{
    GetGateUserManager().AddUser(conn);
}

void Gateway::OnConnected(const ConnectionPtr& /*conn*/, bool /*success*/)
{
}

uint32 Gateway::OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len)
{
    if (len >= MAX_RECV_BUF) {
        LOG("Recv buffer overflow, shutdown this connection");
        conn->Shutdown();
        return len;
    }

    uint32 total_len = 0;
    while (len > sizeof(PacketHeader)) {
        PacketHeader* p = (PacketHeader*)buf;
        uint32        cur_len = p->len + sizeof(PacketHeader);
        if (len < cur_len) {
            break;
        }

        Dispatch(conn, p->buf, p->len);

        total_len += cur_len;
        buf += cur_len;
        len -= cur_len;
    }

    return total_len;
}

void Gateway::OnWrite(const ConnectionPtr& /*conn*/, uint32 /*len*/)
{
}

void Gateway::OnDisconnect(const ConnectionPtr& conn)
{
    uint32 conn_id = conn->GetId();

    UserDisconnect(conn_id);
}
