#ifndef _PACKETDATACACHE_H
#define _PACKETDATACACHE_H

#include <map>
#include <mutex>
#include <queue>
#include <string>
#include <tuple>


#define REQUEST_TYPE_NULL -1
enum {
    REQUEST_TYPE_ROOM_CONFIG = 0,
    REQUEST_TYPE_ARENA_CONFIG,
    REQUEST_TYPE_VIP_CONFIG,
    REQUEST_TYPE_LEV_CONFIG,
    REQUEST_TYPE_ACTIVITY_CONFIG,
    REQUEST_TYPE_LOGIN,
    REQUEST_TYPE_FRIENDS,
    REQUEST_TYPE_SAVEDATA,
    REQUEST_TYPE_BAGGAGE,
    REQUEST_TYPE_UPDATEFRIENDS,
    REQUEST_TYPE_USERINFO,
    REQUEST_TYPE_MAX,
};
class PacketDataCacheMgr {
    typedef std::map<std::string, std::queue<std::tuple<unsigned, int, std::string>>> cache;

public:
    PacketDataCacheMgr()
    {
    }

public:
    template <typename... Args>
    void Push(const std::string& uuid, int type, unsigned conn_id, Args... args)
    {
        std::lock_guard<std::mutex> l(mutex_);
        std::ostringstream          ost;
        Params(ost, args...);

        cache_[uuid].push(std::make_tuple(type, conn_id, ost.str()));
    }
    int Pop(const std::string& uuid, unsigned& conn_id, std::string& data)
    {
        std::lock_guard<std::mutex> l(mutex_);
        auto                        iter = cache_.find(uuid);
        if (iter == cache_.end())
            return REQUEST_TYPE_NULL;

        auto& q = iter->second;
        if (q.empty())
            return REQUEST_TYPE_NULL;

        auto& t = q.front();

        int type = std::get<0>(t);
        conn_id = std::get<1>(t);
        data = std::get<2>(t);

        q.pop();

        return type;
    }

    unsigned GetConnId(const std::string& uuid)
    {
        std::lock_guard<std::mutex> l(mutex_);
        auto                        iter = cache_.find(uuid);
        if (iter == cache_.end())
            return -1;

        if (iter->second.empty())
            return -1;

        auto& q = iter->second;
        auto& t = q.front();

        return std::get<0>(t);
    }

private:
    template <typename... Args>
    void Params(std::ostringstream& ost, Args... args)
    {
    }
    template <typename T, typename... Args>
    void Params(std::ostringstream& ost, T t, Args... args)
    {
        ost << Param(t) << ':';

        Params(ost, args...);
    }
    template <typename T>
    std::string Param(T t)
    {
        std::ostringstream ost;
        ost << t;
        return ost.str();
    }

private:
    std::mutex mutex_;
    cache      cache_;
};  // PacketDataCacheMgr

inline PacketDataCacheMgr& GetPacketDataCacheMgr()
{
    static PacketDataCacheMgr mgr;
    return mgr;
}

#endif  // _PACKETDATACACHE_H
