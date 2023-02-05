#ifndef _CLIENT_H
#define _CLIENT_H

#include <string>
#include "../ServerLib/TcpClient.h"

class Client {
public:
    using redis_data = std::vector<std::string>;

public:
    Client(const std::string& host, const std::string& port);

public:
    void Init(IoService& ios);
    void Connect();

public:
    void   OnConnected(const ConnectionPtr& conn, bool success);
    uint32 OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len);
    void   OnWrite(const ConnectionPtr& conn, uint32 len);
    void   OnDisconnect(const ConnectionPtr& conn);

public:
    void Send(const uint8* buf, int len);
    void Send(const std::string& buf);

public:
    virtual void   Connected(const ConnectionPtr& conn) = 0;
    virtual uint32 Handler(const uint8* buf, uint32 len) = 0;

protected:
    std::string  host_, port_;
    TcpClientPtr client_;
};  // Client

#endif  // _CLIENT_H
