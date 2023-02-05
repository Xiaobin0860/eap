#ifndef _REDISCLIENT_H
#define _REDISCLIENT_H

#include <map>
#include <string>
#include <vector>


#include "Client.h"

namespace PB {
class Packet;
}

#define TBL_ROOM_CONFIG "ROOM_CONFIG"
#define TBL_ARENA_CONFIG "ARENA_CONFIG"
#define TBL_VIP_CONFIG "VIP_CONFIG"
#define TBL_LEV_CONFIG "LEV_CONFIG"
#define TBL_ACTIVITY_CONFIG "ACTIVITY_CONFIG"

#define TBL_LOGIN "LOGIN"
#define TBL_USER "USER"
#define TBL_FRIEND "FRIEND"
#define TBL_BAGGAGE "BAGGAGE"

inline std::string tbl_uuid(const std::string& tbl, const std::string& uuid)
{
    std::string tbl_;
    tbl_ = tbl;
    tbl_ += ':';
    tbl_ += uuid;
    return tbl_;
}

class RedisClient : public Client {
    using FuncHandler = std::function<void(const redis_data&)>;

public:
    RedisClient(const FuncHandler handler, const std::string& host, const std::string& port, const std::string& user,
                const std::string& password);

public:
    virtual void   Connected(const ConnectionPtr& conn);
    virtual uint32 Handler(const uint8* buf, uint32 len);

public:
    template <typename... Args>
    void Execute(const std::string& opt, const std::string& game, const std::string& tbl, Args... args)
    {
        int c = sizeof...(args);
        c++;  // opt
        c++;  // tbl

        std::string tbl_;
        tbl_ = game;
        tbl_ += ':';
        tbl_ += tbl;

        std::ostringstream ost;
        ost << '*' << c << "\r\n";
        ost << '$' << opt.length() << "\r\n" << opt << "\r\n";

        ost << '$' << tbl_.length() << "\r\n" << tbl_ << "\r\n";

        Params(ost, args...);
        Execute(ost);
    }

    void Execute(const std::ostringstream& ost);

    template <typename K, typename... Args>
    void Set(const std::string& opt, const std::string& game, const std::string& tbl, const K& k, Args... args)
    {
        int c = sizeof...(args);
        c++;
        c++;

        std::string tbl_;
        tbl_ = game;
        tbl_ += ':';
        tbl_ += tbl;

        std::ostringstream ost;
        ost << '*' << c << "\r\n";
        ost << '$' << opt.length() << "\r\n" << opt << "\r\n";
        ost << '$' << tbl_.length() << "\r\n" << tbl_ << "\r\n";

        Params(true, ost, tbl_, k, args...);

        Execute(ost);
    }

    template <typename K, typename... Args>
    void Get(const std::string& opt, const std::string& game, const std::string& tbl, const K& k, Args... args)
    {
        int c = sizeof...(args);
        c++;
        c++;

        std::string tbl_;
        tbl_ = game;
        tbl_ += ':';
        tbl_ += tbl;

        std::ostringstream ost;
        ost << '*' << c << "\r\n";
        ost << '$' << opt.length() << "\r\n" << opt << "\r\n";

        ost << '$' << tbl_.length() << "\r\n" << tbl_ << "\r\n";

        Params(false, ost, tbl_, k, args...);

        Execute(ost);
    }

private:
    //////////////////////////////////////////////////////////////////////////
    // Prams
    template <typename... Args>
    void Params(std::ostringstream& ost, Args... args)
    {
    }
    template <typename T, typename... Args>
    void Params(std::ostringstream& ost, T t, Args... args)
    {
        std::string str = Param(t);

        ost << '$' << str.length() << "\r\n" << str << "\r\n";

        Params(ost, args...);
    }
    //////////////////////////////////////////////////////////////////////////
    // Set prams
    template <typename K, typename... Args>
    void Params(bool flag, std::ostringstream& ost, const std::string& tbl, const K& k, Args... args)
    {
    }
    template <typename K, typename T, typename... Args>
    void Params(bool flag, std::ostringstream& ost, const std::string& tbl, const K& k, T t, Args... args)
    {
        int         c = sizeof...(args);
        std::string str = c % 2 || !flag ? Param(tbl, k, t) : Param(t);

        ost << '$' << str.length() << "\r\n" << str << "\r\n";

        Params(flag, ost, tbl, k, args...);
    }

    //////////////////////////////////////////////////////////////////////////
    template <typename K, typename T>
    std::string Param(const std::string& tbl, const K& k, T t)
    {
        std::ostringstream ost;
        ost << tbl << ':' << k << ':' << t;
        return ost.str();
    }
    template <typename T>
    std::string Param(T t)
    {
        std::ostringstream ost;
        ost << t;
        return ost.str();
    }

private:
    FuncHandler handler_;
    std::string user_, password_;
};  // RedisClient

#endif  // _REDISCLIENT_H
