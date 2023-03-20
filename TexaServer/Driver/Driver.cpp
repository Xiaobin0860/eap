#include "Driver.h"

#include "GameScript.h"
#include "LuaBinder.h"
#include "LuaVM.h"

Driver* driver = 0;

Driver::Driver(const std::string& ip, const std::string& port, const std::string& name, const std::string& script_entry)
    : gate_ip_(ip)
    , gate_port_(port)
    , game_name_(name)
{
    logger_.reset(new services::logger(ios_, ""));

    client_.reset(new TcpClient(ios_));
    client_->SetCallBacks(GetCallBacks());

    script_.reset(new GameScript(script_entry));
    script_->Init();

    timer_mgr_.reset(new TimerMgr(ios_));
    script_timer_ = timer_mgr_->AddTimer(script_->GetScriptFrameFunc(), SCRIPT_FRAME_INTERVAL);
}

void Driver::Run()
{
    client_->Connect(gate_ip_, gate_port_);
    ios_.run();
}

void Driver::Stop()
{
    timer_mgr_->Cancel(script_timer_);
    script_->Stop();
}

void Driver::OnConnected(const ConnectionPtr& /*conn*/, bool success)
{
    if (!success) {
        LOG("Gate server connect fail, retry now");
        client_->Connect(gate_ip_, gate_port_);
    } else {
        printf("Successfully connect to gate server\n");
        LoginToGate();
    }
}

uint32 Driver::OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len)
{
    if (len > MAX_RECV_BUF) {
        return len;
    }

    uint32 total_len = 0;
    while (len > sizeof(PacketHeader)) {
        PacketHeader* p = (PacketHeader*)buf;
        uint32        cur_len = p->len + sizeof(PacketHeader);
        if (len < p->len) {
            break;
        }

        Dispatch(p->buf, p->len);

        total_len += cur_len;
        buf += cur_len;
        len -= cur_len;
    }

    return total_len;
}

void Driver::OnWrite(const ConnectionPtr& /*conn*/, uint32 /*len*/)
{
}

void Driver::OnDisconnect(const ConnectionPtr& conn)
{
    LOG("disconnected from gate server, try to reconnect");
    client_->Shutdown();
    client_->Connect(gate_ip_, gate_port_);
}
