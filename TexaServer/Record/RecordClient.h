#ifndef _RECORDCLIENT_H
#define _RECORDCLIENT_H

#include "Client.h"

namespace PB {
class ForwardingPacket;
}
namespace ClientGate {
class BasicUserInfo;
}

class Storage;
class RedisClient;
class RecordClient : public Client {
    using PktHandler = std::function<void(const PB::ForwardingPacket&)>;
    using RHandler = std::function<void(const std::string&, const uint32, const std::string&, const redis_data&)>;

#define PKT_TYPE_NULL -1
#define MAX_PKT_TYPES 0x1000

    enum {
        PKT_TYPE_COMMON = 0,
        PKT_TYPE_GATEWAY,
        PKT_TYPE_CLIENT,
        PKT_TYPE_TEXASPOKER,
        PKT_TYPE_MAX,
    };

public:
    RecordClient(Storage& storage, const std::string& game_name, const int64 default_score, const std::string& host,
                 const std::string& port);

    void SetRedis(RedisClient* redis);
    void InitRedis();

public:
    void Dispatch(const uint8* buf, int len);
    void Handler(const PB::ForwardingPacket& packet);

    void LoginHandler(const PB::ForwardingPacket& packet);
    void SaveDataHandler(const PB::ForwardingPacket& packet);
    void UseItemHandler(const PB::ForwardingPacket& packet);
    void UpdateFriendHandler(const PB::ForwardingPacket& packet);
    void GetUserInfoHandler(const PB::ForwardingPacket& packet);

public:
    void RedisHandler(const redis_data& data);
    void HandleRoomConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                          const redis_data& data);
    void HandleArenaConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                           const redis_data& data);
    void HandleVipConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                         const redis_data& data);
    void HandleLevConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                         const redis_data& data);
    void HandleActivityConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                              const redis_data& data);
    void HandleLogin(const std::string& uuid, const uint32 conn_id, const std::string& params, const redis_data& data);
    void HandleFriends(const std::string& uuid, const uint32 conn_id, const std::string& params,
                       const redis_data& data);
    void HandleSaveData(const std::string& uuid, const uint32 conn_id, const std::string& params,
                        const redis_data& data);
    void HandleBaggage(const std::string& uuid, const uint32 conn_id, const std::string& params,
                       const redis_data& data);
    void HandleGetUserInfo(const std::string& uuid, const uint32 conn_id, const std::string& params,
                           const redis_data& data);
    void HandleUpdateFriend(const std::string& uuid, const uint32 conn_id, const std::string& params,
                            const redis_data& data);

public:
    int  Proc_Registe(std::string& uuid, const std::string& name, const std::string& password, const std::string& nick,
                      const int gender);
    void Proc_Login(const std::string& uuid, const std::string& name, const std::string& password);

public:
    virtual void   Connected(const ConnectionPtr& conn);
    virtual uint32 Handler(const uint8* buf, uint32 len);

private:
    void Login();
    void SaveBalance(ClientGate::BasicUserInfo& user, const int64 balance);
    void SaveExp(ClientGate::BasicUserInfo& user, const uint64 exp);
    void SaveLev(ClientGate::BasicUserInfo& user, const uint64 lev);
    void SaveVip(ClientGate::BasicUserInfo& user, const uint64 vip);
    void SaveActivity(ClientGate::BasicUserInfo& user, const uint64 activity);
    void SaveAddFriend(const std::string& uuid, const std::string& friend_id);
    void SaveDelFriend(const std::string& uuid, const std::string& friend_id);

private:
    Storage&                     storage_;
    std::string                  game_name_;
    int64                        default_score_;
    std::shared_ptr<RedisClient> redis_;
    PktHandler                   phandler_[PKT_TYPE_MAX][MAX_PKT_TYPES];
    RHandler                     rhandler_[MAX_PKT_TYPES];
};  // RecordClient

#endif  // _RECORDCLIENT_H
