#ifndef _DRIVER_H
#define _DRIVER_H

#include "../ServerLib/TcpClient.h"
#include "../ServerLib/TimerMgr.h"

#include "../Common/Misc.h"

#include "GameScript.h"

#include "Gateway.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"

#define SCRIPT_FRAME_INTERVAL 6  // ms

class Driver {
public:
    Driver(const std::string& ip, const std::string& port, const std::string& name, const std::string& script_entry);

public:
    void Run();
    void Stop();

    void Send(const std::string& pkt);

    uint32 StartTimer(uint32 table_id, const std::string& timer_func, uint32 interval);
    void   StopTimer(uint32 timer_id);
    int32  GetRestTime(uint32 timer_id);

private:
    template <typename T>
    void SendToGate(Protocol::ClientGateProtocol cmd, const T& pkt);

private:
    void LoginToGate();

private:
    ConnectionCallBacks GetCallBacks();

private:
    // handler
    void Dispatch(const uint8* buf, uint32 len);

    // call backs
    void   OnConnected(const ConnectionPtr& conn, bool success);
    uint32 OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len);
    void   OnWrite(const ConnectionPtr& conn, uint32 len);
    void   OnDisconnect(const ConnectionPtr& conn);

private:
    IoService     ios_;
    TcpClientPtr  client_;
    GameScriptPtr script_;
    TimerMgrPtr   timer_mgr_;

    std::string gate_ip_, gate_port_;
    std::string game_name_;

    uint32 script_timer_;
};
extern Driver* driver;

inline ConnectionCallBacks Driver::GetCallBacks()
{
    ConnectionCallBacks cb = {
        std::bind(&Driver::OnConnected, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Driver::OnRead, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3),
        std::bind(&Driver::OnWrite, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Driver::OnDisconnect, this, std::placeholders::_1),
    };
    return cb;
}

template <typename T>
void Driver::SendToGate(Protocol::ClientGateProtocol cmd, const T& pkt)
{
    PB::Packet packet;
    packet.set_command(cmd);

    pkt.SerializeToString(packet.mutable_serialized());
    uint32 len = packet.ByteSize();

    FastBuf<uint8> buf(len + 4);
    packet.SerializeToArray(buf.buf + 4, len);
    memcpy(buf.buf, &len, 4);
    client_->Send(buf.buf, len + 4);
}

#endif  // _DRIVER_H
