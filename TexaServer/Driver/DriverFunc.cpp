#include "Driver.h"

#include "../ServerLib/md5.h"

#include "GameScript.h"
#include "LuaVM.h"

#include "Gateway.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"

void Driver::Send(const std::string& pkt)
{
    int            len = pkt.size();
    FastBuf<uint8> buf(len + 4);
    memcpy(buf.buf, &len, 4);
    memcpy(buf.buf + 4, pkt.c_str(), len);
    client_->Send(buf.buf, len + 4);
}

uint32 Driver::StartTimer(uint32 table_id, const std::string& timer_func, uint32 interval)
{
    auto func = [&](uint32 table_id, const std::string& timer_func) { script_->GetVM()->Call(timer_func, table_id); };
    return timer_mgr_->AddTimer(std::bind(func, table_id, timer_func), interval);
}

void Driver::StopTimer(uint32 timer_id)
{
    timer_mgr_->Cancel(timer_id);
}

int32 Driver::GetRestTime(uint32 timer_id)
{
    return timer_mgr_->GetRestTime(timer_id);
}

void Driver::Dispatch(const uint8* buf, uint32 len)
{
    script_->OnUserData(buf, len);
}

void Driver::LoginToGate()
{
    GatewayServer::LoginRequest request;

    GatewayServer::EnumServerType type = GatewayServer::ST_GameServer;
    request.set_server_type(type);

    request.set_account(game_name_);

    std::string tmp(game_name_ + std::to_string(type));
    std::string key = GetMD5((md5byte*)tmp.c_str(), tmp.size());
    request.set_secure_key(key);

    SendToGate(Protocol::SERVER_LOGIN_REQUEST, request);
}
