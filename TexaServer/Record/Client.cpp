#include "Client.h"
#include "../ServerLib/ServerCommon.h"

Client::Client(const std::string& host, const std::string& port)
{
    host_ = host;
    port_ = port;
}

void Client::Init(IoService& ios)
{
    client_.reset(new TcpClient(ios));

    ConnectionCallBacks cb = {
        std::bind(&Client::OnConnected, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Client::OnRead, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3),
        std::bind(&Client::OnWrite, this, std::placeholders::_1, std::placeholders::_2),
        std::bind(&Client::OnDisconnect, this, std::placeholders::_1),
    };
    client_->SetCallBacks(cb);

    Connect();
}

void Client::Connect()
{
    client_->Connect(host_, port_);
}

void Client::OnConnected(const ConnectionPtr& conn, bool success)
{
    if (!success) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        Connect();
    } else {
        printf("%s %s:%s\n", __FUNCTION__, host_.c_str(), port_.c_str());
        LOG("%s %s:%s\n", __FUNCTION__, host_.c_str(), port_.c_str());
        Connected(conn);
    }
}

void Client::OnWrite(const ConnectionPtr& conn, uint32 len)
{
}

void Client::OnDisconnect(const ConnectionPtr& conn)
{
    printf("%s %s:%s\n", __FUNCTION__, host_.c_str(), port_.c_str());
    Connect();
}

uint32 Client::OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len)
{
    if (len >= MAX_RECV_BUF) {
        LOG("Recv buffer overflow, shutdown this connection");
        conn->Shutdown();
        return len;
    }

    return Handler(buf, len);
}

void Client::Send(const uint8* buf, int len)
{
    client_->Send(buf, len);
}

void Client::Send(const std::string& buf)
{
    Send((const uint8*)buf.c_str(), buf.length());
}
