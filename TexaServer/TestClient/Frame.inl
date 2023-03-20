
void ConnectToGate()
{
    client->Connect("127.0.0.1", "8990");
}

void OnConnected(const ConnectionPtr& conn, bool success)
{
    printf("connect %s\n", success ? "success" : "fail");
    if (success) {
        Login();
        GetUsers();
        LookTable1();
    } else {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        ConnectToGate();
    }
}
uint32 OnRead(const ConnectionPtr& conn, const uint8* buf, uint32 len)
{
    if (len > MAX_RECV_BUF) {
        return len;
    }

    uint32 conn_id = conn->GetId();

    uint32 total_len = 0;
    while (len > sizeof(PacketHeader)) {
        PacketHeader* p = (PacketHeader*)buf;
        uint32        cur_len = p->len + sizeof(PacketHeader);
        if (len < cur_len) {
            break;
        }

        Dispatch(conn_id, p->buf, p->len);

        total_len += cur_len;
        buf += cur_len;
        len -= cur_len;
    }

    return total_len;
}
void OnWrite(const ConnectionPtr& conn, uint32 len)
{
    printf("%s: %d\n", __FUNCTION__, len);
}
void OnDisconnect(const ConnectionPtr& conn)
{
    ConnectToGate();
}
inline ConnectionCallBacks GetCallBacks()
{
    ConnectionCallBacks cb = {
        std::bind(&OnConnected, std::placeholders::_1, std::placeholders::_2),
        std::bind(&OnRead, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3),
        std::bind(&OnWrite, std::placeholders::_1, std::placeholders::_2),
        std::bind(&OnDisconnect, std::placeholders::_1),
    };
    return cb;
}
