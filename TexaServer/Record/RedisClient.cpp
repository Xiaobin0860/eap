#include "RedisClient.h"

#include "Protocol.pb.h"

RedisClient::RedisClient(const FuncHandler handler, const std::string& host, const std::string& port,
                         const std::string& user, const std::string& password)
    : Client(host, port)
    , handler_(handler)
    , user_(user)
    , password_(password)
{
}

void RedisClient::Execute(const std::ostringstream& ost)
{
    Send(ost.str());
}

static uint32 line_len(const uint8* buf, int len)
{
    uint32 len_ = 0;
    for (;;) {
        if (len == 0)
            return 0;

        if (len >= 2) {
            if (buf[0] == '\r' && buf[1] == '\n')
                return len_ + 2;
        }

        len_++;
        buf++;
        len--;
    }

    return len_;
}
static std::string line_str(const uint8* buf)
{
    const char* str = (const char*)(buf + 1);
    const char* e = strstr(str, "\r\n");
    if (!e)
        return "";

    return std::string(str, e - str);
}
static std::string line_str(const uint8* buf, int l)
{
    if (l <= 0)
        return "";

    const char* str = (const char*)buf;
    return std::string(str, l);
}
static int32 CountParams(const uint8* buf, uint32 len)
{
    if (len < 3)
        return -1;

    if (buf[0] == '+' || buf[0] == '-')
        return 0;

    if (buf[0] != '*')
        return -1;

    uint32 l = line_len(buf, len);
    if (!l)
        return -1;

    return atoi((char*)buf + 1);
}
static uint32 SplitParam(std::vector<std::string>& params, const uint8* buf, uint32 len)
{
    if (len <= 1)
        return 0;

    switch (buf[0]) {
    case '+':
    case '-':
        return line_len(buf, len);
    case '*': {
        uint32 l = line_len(buf, len);
        if (!l)
            return 0;

        std::string str = line_str(buf);
        int         n = atoi(str.c_str());
        buf += l;
        len -= l;
        for (int32 i = 0; i < n; i++) {
            uint32 l1 = SplitParam(params, buf, len);
            if (!l1)
                return 0;

            buf += l1;
            len -= l1;
            l += l1;
        }

        return l;
    }
    case '$': {
        std::string str = line_str(buf);
        uint32      l = line_len(buf, len);

        int n = atoi(str.c_str());

        str.clear();

        uint32 l1 = 0;
        if (n >= 0) {
            l1 = n + 2;
            str = line_str(buf + l, n);
        }

        params.push_back(str);
        return l + l1;
    }
    case ':': {
        std::string str = line_str(buf);
        params.push_back(str);
        return line_len(buf, len);
    }
    default:
        return 1;
    }
}

// login redis
void RedisClient::Connected(const ConnectionPtr& conn)
{
    DEF_AUTO_LOG_FUNC();
}

uint32 RedisClient::Handler(const uint8* buf, uint32 len)
{
    redis_data lines;
    uint32     total_len = 0;
    for (;;) {
        lines.clear();
        uint32 l = SplitParam(lines, buf, len);
        if (!l)
            break;

        int c = CountParams(buf, len);
        if (c != lines.size())
            break;

        if (lines.size())
            handler_(lines);

        total_len += l;
        buf += l;
        len -= l;
    }

    return total_len;
}
