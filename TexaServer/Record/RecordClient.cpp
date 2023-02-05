#include "RecordClient.h"

#include "../ServerLib/md5.h"
#include "../ServerLib/strop.h"

#include "ClientGate.pb.h"
#include "DBGate.pb.h"
#include "Gateway.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"


#include "RedisClient.h"
#include "SendPacket.h"
#include "Storage.h"


#include "PacketDataCache.h"
#include "UUIDMgr.h"


#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>

#define bind_phander(f) std::bind(&RecordClient::##f, this, std::placeholders::_1)
#define bind_rhandler(f)                                                                                               \
    std::bind(&RecordClient::##f, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3,           \
              std::placeholders::_4)

RecordClient::RecordClient(Storage& storage, const std::string& game_name, const int64 default_score,
                           const std::string& host, const std::string& port)
    : storage_(storage)
    , game_name_(game_name)
    , default_score_(default_score)
    , Client(host, port)
{
    phandler_[PKT_TYPE_CLIENT][Protocol::CLIENT_LOGIN_REQUEST - Protocol::CLIENT_LOGIN_REQUEST] =
        bind_phander(LoginHandler);
    phandler_[PKT_TYPE_CLIENT][Protocol::CLIENT_USE_ITEM_REQUECT - Protocol::CLIENT_LOGIN_REQUEST] =
        bind_phander(UseItemHandler);
    phandler_[PKT_TYPE_CLIENT][Protocol::CLIENT_UPDATE_FRIEND - Protocol::CLIENT_LOGIN_REQUEST] =
        bind_phander(UpdateFriendHandler);
    phandler_[PKT_TYPE_CLIENT][Protocol::CLIENT_GET_USERINFO - Protocol::CLIENT_LOGIN_REQUEST] =
        bind_phander(GetUserInfoHandler);
    phandler_[PKT_TYPE_GATEWAY][Protocol::SAVE_DATA - Protocol::SERVER_LOGIN_REQUEST] = bind_phander(SaveDataHandler);

    rhandler_[REQUEST_TYPE_ROOM_CONFIG] = bind_rhandler(HandleRoomConfig);
    rhandler_[REQUEST_TYPE_ARENA_CONFIG] = bind_rhandler(HandleArenaConfig);
    rhandler_[REQUEST_TYPE_VIP_CONFIG] = bind_rhandler(HandleVipConfig);
    rhandler_[REQUEST_TYPE_LEV_CONFIG] = bind_rhandler(HandleLevConfig);
    rhandler_[REQUEST_TYPE_ACTIVITY_CONFIG] = bind_rhandler(HandleActivityConfig);
    rhandler_[REQUEST_TYPE_LOGIN] = bind_rhandler(HandleLogin);
    rhandler_[REQUEST_TYPE_FRIENDS] = bind_rhandler(HandleFriends);
    rhandler_[REQUEST_TYPE_SAVEDATA] = bind_rhandler(HandleSaveData);
    rhandler_[REQUEST_TYPE_BAGGAGE] = bind_rhandler(HandleBaggage);
    rhandler_[REQUSET_TYPE_USERINFO] = bind_rhandler(HandleGetUserInfo);
    rhandler_[REQUEST_TYPE_UPDATEFRIENDS] = bind_rhandler(HandleUpdateFriend);
}

void RecordClient::SetRedis(RedisClient* redis)
{
    redis_.reset(redis);
}

void RecordClient::InitRedis()
{
    storage_.EnumUser(std::bind(
        [this](const std::string& user, const std::string& pwd, const ClientGate::BasicUserInfo& info) {
            auto rset_lst = [this](const std::string& tbl, const std::string& uuid) {
                redis_->Execute("DEL", game_name_, tbl_uuid(tbl, uuid));
                redis_->Execute("LPUSH", game_name_, tbl_uuid(tbl, uuid), uuid);
            };

            auto& uuid = info.user_id();
            redis_->Set("HMSET", game_name_, TBL_USER, info.user_id(), "uuid", uuid, "name", user, "password", pwd,
                        "desc", info.SerializeAsString());

            GetUUIDMgr().Add(user, info.user_id());

            rset_lst(TBL_FRIEND, uuid);
        },
        std::placeholders::_1, std::placeholders::_2, std::placeholders::_3));

    storage_.EnumRoomConfig(std::bind(
        [this](uint64 id, const DBGate::RoomConfig& config) {
            redis_->Set("HMSET", game_name_, TBL_ROOM_CONFIG, id, "desc", config.SerializeAsString());
        },
        std::placeholders::_1, std::placeholders::_2));

    storage_.EnumArenaConfig(std::bind(
        [this](uint64 id, const DBGate::ArenaConfig& config) {
            redis_->Set("HMSET", game_name_, TBL_ARENA_CONFIG, id, "desc", config.SerializeAsString());
        },
        std::placeholders::_1, std::placeholders::_2));

    storage_.EnumVipConfig(std::bind(
        [this](const DBGate::VipConfig& config) {
            redis_->Set("HMSET", game_name_, TBL_VIP_CONFIG, config.lev(), "desc", config.SerializeAsString());
        },
        std::placeholders::_1));

    storage_.EnumLevConfig(std::bind(
        [this](const DBGate::LevConfig& config) {
            redis_->Set("HMSET", game_name_, TBL_LEV_CONFIG, config.lev(), "desc", config.SerializeAsString());
        },
        std::placeholders::_1));

    storage_.EnumActivityConfig(std::bind(
        [this](const uint64 id, const DBGate::ActivityConfig& config) {
            redis_->Set("HMSET", game_name_, TBL_ACTIVITY_CONFIG, id, "desc", config.SerializeAsString());
        },
        std::placeholders::_1, std::placeholders::_2));

    storage_.EnumFriend(std::bind(
        [this](const std::string& uuid, const std::string& friend_id) {
            redis_->Execute("RPUSH", game_name_, tbl_uuid(TBL_FRIEND, uuid), friend_id);
        },
        std::placeholders::_1, std::placeholders::_2));

    storage_.EnumBaggage(std::bind(
        [this](const std::string& uuid, const std::string& desc) {
            redis_->Set("HMSET", game_name_, TBL_BAGGAGE, uuid, "uuid", uuid, "desc", desc);
        },
        std::placeholders::_1, std::placeholders::_2));

    printf("redis init end\n");
}

#define PushSpeicalRequest(tbl, type)                                                                                  \
    GetPacketDataCacheMgr().Push(tbl, type, conn->GetId());                                                            \
    redis_->Execute("HGETALL", game_name_, tbl);

void RecordClient::Connected(const ConnectionPtr& conn)
{
    DEF_AUTO_LOG_FUNC();
    Login();

    PushSpeicalRequest(TBL_ROOM_CONFIG, REQUEST_TYPE_ROOM_CONFIG);
    PushSpeicalRequest(TBL_ARENA_CONFIG, REQUEST_TYPE_ARENA_CONFIG);
    PushSpeicalRequest(TBL_VIP_CONFIG, REQUEST_TYPE_VIP_CONFIG);
    PushSpeicalRequest(TBL_LEV_CONFIG, REQUEST_TYPE_LEV_CONFIG);
    PushSpeicalRequest(TBL_ACTIVITY_CONFIG, REQUEST_TYPE_ACTIVITY_CONFIG);
}

void RecordClient::Dispatch(const uint8* buf, int len)
{
    PB::ForwardingPacket packet;
    if (!packet.ParseFromArray(buf, len))
        return;
    Handler(packet);
}

uint32 RecordClient::Handler(const uint8* buf, uint32 len)
{
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

//////////////////////////////////////////////////////////////////////////
void RecordClient::Login()
{
    GatewayServer::LoginRequest request;
    request.set_server_type(GatewayServer::ST_RecordServer);
    request.set_account("ST_RecordServer");

    std::string account = request.account() + std::to_string(GatewayServer::ST_RecordServer);
    std::string md5 = GetMD5((md5byte*)account.c_str(), account.length());
    request.set_secure_key(md5);

    SendPacket(client_, Protocol::SERVER_LOGIN_REQUEST, request);
}

void RecordClient::SaveBalance(ClientGate::BasicUserInfo& user, const int64 balance)
{
    user.set_user_score(balance);
    redis_->Set("HMSET", game_name_, TBL_USER, user.user_id(), "desc", user.SerializeAsString());
    storage_.SaveData(user.user_id(), "balance", std::to_string(balance));
}

void RecordClient::SaveExp(ClientGate::BasicUserInfo& user, const uint64 exp)
{
    user.set_experience(exp);
    redis_->Set("HMSET", game_name_, TBL_USER, user.user_id(), "desc", user.SerializeAsString());
    storage_.SaveData(user.user_id(), "exp", std::to_string(exp));
}

void RecordClient::SaveLev(ClientGate::BasicUserInfo& user, const uint64 lev)
{
    user.set_lev(lev);
    redis_->Set("HMSET", game_name_, TBL_USER, user.user_id(), "desc", user.SerializeAsString());
    storage_.SaveData(user.user_id(), "lev", std::to_string(lev));
}

void RecordClient::SaveVip(ClientGate::BasicUserInfo& user, const uint64 vip)
{
    user.set_vip(vip);
    redis_->Set("HMSET", game_name_, TBL_USER, user.user_id(), "desc", user.SerializeAsString());
    storage_.SaveData(user.user_id(), "vip", std::to_string(vip));
}

void RecordClient::SaveActivity(ClientGate::BasicUserInfo& user, const uint64 activity)
{
    user.set_activity(activity);
    storage_.SaveData(user.user_id(), "activity", std::to_string(activity));
}

void RecordClient::SaveAddFriend(const std::string& uuid, const std::string& friend_id)
{
    redis_->Execute("RPUSH", game_name_, tbl_uuid(TBL_FRIEND, uuid), friend_id);
    storage_.UpdateFriendShip(uuid, friend_id, 1);
}

void RecordClient::SaveDelFriend(const std::string& uuid, const std::string& friend_id)
{
    redis_->Execute("LREM", game_name_, tbl_uuid(TBL_FRIEND, uuid), friend_id);
    storage_.UpdateFriendShip(uuid, friend_id, 1);
}
//////////////////////////////////////////////////////////////////////////
int32 RecordClient::Proc_Registe(std::string& uuid, const std::string& name, const std::string& password,
                                 const std::string& nick, const int gender)
{
    if (!uuid.empty()) {
        return 0;
    }

    boost::uuids::random_generator rnd_gen;
    uuid = boost::uuids::to_string(rnd_gen());

    if (!storage_.OnRegist(uuid, name, password, nick, gender, default_score_))
        return -1;

    ClientGate::BasicUserInfo info;
    info.set_user_id(uuid);
    info.set_nick(nick);
    info.set_avatar("");
    info.set_gender((ClientGate::EnumGender)gender);
    info.set_user_score(default_score_);
    info.set_lev(0);
    info.set_experience(0);
    info.set_vip(0);
    info.set_activity(0);

    redis_->Set("HMSET", game_name_, TBL_USER, uuid, "uuid", uuid, "name", name, "password", password, "desc",
                info.SerializeAsString());

    return 0;
}

void RecordClient::Proc_Login(const std::string& uuid, const std::string& name, const std::string& password)
{
    redis_->Get("HMGET", game_name_, TBL_USER, uuid, "uuid", "password", "desc");
#ifdef WIN32
    printf("%s [%s, %s, %s]\n", __FUNCTION__, uuid.c_str(), name.c_str(), password.c_str());
#endif
}
