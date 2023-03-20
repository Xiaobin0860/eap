#ifndef _STORAGE_H
#define _STORAGE_H

#include <functional>
#include <mutex>
#include <queue>
#include <string>


#include "../Common/Types.h"

namespace sql {
class Connection;
}

namespace DBGate {
class RoomConfig;
class ArenaConfig;
class VipConfig;
class LevConfig;
class ActivityConfig;
}  // namespace DBGate
namespace ClientGate {
class BasicUserInfo;
}

class Storage {
    using user_sql = std::queue<std::string>;

public:
    Storage(const std::string& ip, const std::string& port, const std::string& user, const std::string& pass,
            const std::string& db_name, int thread_count);

public:
    bool Init();
    bool Connect();
    bool SelectDB();
    bool FlushDB(const std::string& sql);

    void PushSql(const std::string& sql);
    bool NextSql(std::string& sql);

public:
    bool OnRegist(const std::string& uuid, const std::string& name, const std::string& password,
                  const std::string& nick, const int gender, const int64 default_score);

    void EnumUser(std::function<void(const std::string&, const std::string&, const ClientGate::BasicUserInfo&)> fun);
    void EnumRoomConfig(std::function<void(uint64, const DBGate::RoomConfig&)> fun);
    void EnumArenaConfig(std::function<void(uint64, const DBGate::ArenaConfig&)> fun);
    void EnumVipConfig(std::function<void(const DBGate::VipConfig&)> fun);
    void EnumLevConfig(std::function<void(const DBGate::LevConfig&)> fun);
    void EnumActivityConfig(std::function<void(const uint64 id, const DBGate::ActivityConfig&)> fun);
    void EnumFriend(std::function<void(const std::string&, const std::string&)> fun);
    void EnumBaggage(std::function<void(const std::string&, const std::string&)> fun);

    void SaveData(const ClientGate::BasicUserInfo& info);
    void SaveData(const std::string& uuid, const std::string& key, const std::string& val);

    void AddFriend(const std::string& uuid, const std::string& friend_id);
    void DelFriend(const std::string& uuid, const std::string& friend_id);
    int  FriendShip(const std::string& uuid, const std::string& friend_id);
    void UpdateFriendShip(const std::string& uuid, const std::string& friend_id, int flag);
    void AddFriendDB(const std::string& uuid, const std::string& friend_id);

private:
    void StartFlushThr();

private:
    std::mutex       mutex_;
    sql::Connection* connection_;

    std::string url_;
    std::string user_, pass_, name_;
    int32       thread_count_;

    std::mutex exec_mutex_;
    user_sql   exec_sql_;

    bool connecting_;
};  // Storage

#endif  // _STORAGE_H
