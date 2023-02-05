#include "RecordClient.h"
#include "RedisClient.h"

#include "../ServerLib/strop.h"

#include "PacketDataCache.h"

#include "ClientGate.pb.h"
#include "DBGate.pb.h"
#include "Gateway.pb.h"
#include "Protocol.pb.h"


#include "Storage.h"

#include "SendPacket.h"

template <typename S, typename C, typename T>
struct Responser {
    Responser(const S& s, const C c)
        : sender_(s)
        , cmd_(c)
        , conn_id(-1)
        , uuid("")
    {
    }
    ~Responser()
    {
        SendPacket(sender_, conn_id, uuid, cmd_, pkt_);
    }

    uint32      conn_id;
    std::string uuid;
    T           pkt_;

private:
    const S& sender_;
    const C  cmd_;
};
void RecordClient::RedisHandler(const redis_data& data)
{
    auto uuid = data[0];
    auto param = SplitString(uuid, ':');
    if (param.size() > 1)
        uuid = param[1];

    uint32      conn_id = -1;
    std::string params;
    auto        request = GetPacketDataCacheMgr().Pop(uuid, conn_id, params);
    auto        proc = rhandler_[request];
    if (!proc)
        return;

    proc(uuid, conn_id, params, data);
}

void RecordClient::HandleRoomConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                    const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameRoomListServer> response(
        client_, Protocol::GAME_INSTANCE_LIST);
    auto& packet = response.pkt_;

    packet.set_game_name(game_name_);
    for (int i = 0; i < (int)data.size(); i += 2) {
        auto  room = packet.add_rooms();
        auto& desc = data[i + 1];
        room->ParseFromString(desc);
    }
}

void RecordClient::HandleArenaConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                     const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameArenaListServer> response(
        client_, Protocol::GAME_ARENA_LIST);
    auto& packet = response.pkt_;

    packet.set_game_name(game_name_);
    for (int i = 0; i < (int)data.size(); i += 2) {
        auto  room = packet.add_rooms();
        auto& desc = data[i + 1];
        room->ParseFromString(desc);
    }
}

void RecordClient::HandleVipConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                   const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameVipListServer> response(client_,
                                                                                              Protocol::GAME_VIP_LIST);
    auto&                                                                            packet = response.pkt_;

    packet.set_game_name(game_name_);
    for (int i = 0; i < (int)data.size(); i += 2) {
        auto  room = packet.add_configs();
        auto& desc = data[i + 1];
        room->ParseFromString(desc);
    }
}

void RecordClient::HandleLevConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                   const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameLevListServer> response(client_,
                                                                                              Protocol::GAME_LEV_LIST);
    auto&                                                                            packet = response.pkt_;

    packet.set_game_name(game_name_);
    for (int i = 0; i < (int)data.size(); i += 2) {
        auto  room = packet.add_configs();
        auto& desc = data[i + 1];
        room->ParseFromString(desc);
    }
}

void RecordClient::HandleActivityConfig(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                        const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameActivityList> response(
        client_, Protocol::GAME_ACTIVITY_LIST);
    auto& packet = response.pkt_;

    packet.set_game_name(game_name_);
    for (int i = 0; i < (int)data.size(); i += 2) {
        auto  room = packet.add_configs();
        auto& desc = data[i + 1];
        room->ParseFromString(desc);
    }
}

void RecordClient::HandleLogin(const std::string& uuid, const uint32 conn_id, const std::string& params,
                               const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, ClientGate::LoginResponse> response(
        client_, Protocol::CLIENT_LOGIN_RESPONSE);
    auto& packet = response.pkt_;
    packet.set_result(ClientGate::enumResultFail);
    if (data.size() < 3)
        return;

    auto& password = data[1];
    auto& desc = data[2];

    response.uuid = uuid;
    response.conn_id = conn_id;

    auto  param = SplitString(params, ':');
    auto& password1 = param[1];
    if (password == password1) {
        auto basic_info = packet.mutable_basic_user_info();
        if (basic_info->ParseFromString(desc)) {
            packet.set_result(ClientGate::enumResultSucc);
#ifdef WIN32
            printf("uuid[%s] login %s\n", uuid.c_str(),
                   packet.result() == ClientGate::enumResultSucc ? "success" : "fail");
#endif  // WIN32
            LOG("[%s] login %s\n", uuid.c_str(), packet.result() == ClientGate::enumResultSucc ? "success" : "fail");
        } else {
            LOG("ParseFromString [%s] login fail\n", uuid.c_str());
        }
    }

    //     GetRequestMgr().Push(uuid, REQUEST_TYPE_FRIENDS);
    //     redis_->Execute("LRANGE", game_name_, tbl_uuid(TBL_FRIEND, uuid), 0, -1);
    //
    //     GetRequestMgr().Push(uuid, REQUEST_TYPE_BAGGAGE);
    //     redis_->Get("HMGET", game_name_, TBL_BAGGAGE, uuid, "uuid", "desc");
}

void RecordClient::HandleSaveData(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                  const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, GatewayServer::SaveDataResponse> response(
        client_, Protocol::SAVE_DATA_RESPONSE);
    auto& packet = response.pkt_;
    packet.set_result(GatewayServer::enumResultFail);
    if (data.size() < 2)
        return;

    auto& desc = data[1];

    auto param = SplitString(params, ':');

    response.conn_id = conn_id;
    response.uuid = uuid;

    if (param.size() < 2)
        return;

    auto& opt = param[0];
    auto& val = param[1];

    ClientGate::BasicUserInfo user_info;
    if (!user_info.ParseFromString(desc))
        return;

    user_info.set_user_id(uuid);
    if (opt == "balance") {
        auto balance = atoll(val.c_str());
        balance += user_info.user_score();
        val = std::to_string(balance);

        SaveBalance(user_info, balance);
    } else if (opt == "exp") {
        auto exp = atoll(val.c_str());
        exp += user_info.experience();
        val = std::to_string(exp);

        SaveExp(user_info, exp);
    } else if (opt == "lev") {
        auto lev = atoll(val.c_str());
        lev += user_info.lev();
        val = std::to_string(lev);

        SaveLev(user_info, lev);
    } else if (opt == "vip") {
        auto vip = atoll(val.c_str());
        vip += user_info.vip();
        val = std::to_string(vip);

        SaveVip(user_info, vip);
    } else if (opt == "activity") {
        auto activity = atoll(val.c_str());
        activity += user_info.activity();
        val = std::to_string(activity);

        SaveActivity(user_info, activity);
    }

    redis_->Set("HMSET", game_name_, TBL_USER, uuid, "desc", user_info.SerializeAsString());

    packet.set_result(GatewayServer::enumResultSucc);
    auto data_ = packet.mutable_data();
    data_->set_name(opt);
    data_->set_str(val);

    LOG("[%s] %s %s %s", uuid.c_str(), __FUNCTION__, opt.c_str(), val.c_str());
}

void RecordClient::HandleBaggage(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                 const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameFrinedList> response(client_,
                                                                                           Protocol::GAME_BAGGAGE);
    if (data.size() < 2)
        return;

    auto& desc = data[1];

    if (desc.empty())
        return;
}

void RecordClient::HandleFriends(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                 const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, DBGate::GameFrinedList> response(client_,
                                                                                           Protocol::GAME_FRIEND_LIST);
    if (data.size() < 2)
        return;

    response.conn_id = conn_id;
    response.uuid = uuid;

    auto& packet = response.pkt_;
    std::for_each(data.begin() + 1, data.end(), [&packet](const std::string& friend_uuid) {
        auto friend_ = packet.add_friends();
        friend_->set_friend_id(friend_uuid);
    });
}

void RecordClient::HandleGetUserInfo(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                     const redis_data& data)
{
    Responser<TcpClientPtr, Protocol::ClientGateProtocol, ClientGate::ClientGetUserInfoResponse> response(
        client_, Protocol::CLIENT_GET_USERINFO_RESPONSE);
    if (data.size() < 2)
        return;

    auto& packet = response.pkt_;
    auto& desc = data[1];

    auto param = SplitString(params, ':');
    if (param.size() < 1)
        return;

    auto& uuid_ = param[0];

    response.conn_id = conn_id;
    response.uuid = uuid_;

    auto basic_user_info = packet.mutable_basic_user_info();
    basic_user_info->ParseFromString(desc);
}

void RecordClient::HandleUpdateFriend(const std::string& uuid, const uint32 conn_id, const std::string& params,
                                      const redis_data& data)
{
}
