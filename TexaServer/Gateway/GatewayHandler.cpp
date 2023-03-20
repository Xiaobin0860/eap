#include "Gateway.h"

#include "../ServerLib/TcpConnection.h"
#include "../ServerLib/fasthash.h"
#include "../ServerLib/md5.h"


#include "ClientGate.pb.h"
#include "DBGate.pb.h"
#include "Gateway.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"


#include "GameMgr.h"
#include "GateUser.h"
#include "Router.h"

#define CHECK_LOGIN(conn_id)                                                                                           \
    {                                                                                                                  \
        auto user = GetGateUserManager().GetUser(conn_id);                                                             \
        if (user == 0) {                                                                                               \
            LOG("Invalid user request in function: %s, should login to server first", __FUNCTION__);                   \
            printf("user %d should login to server first\n", conn_id);                                                 \
            return;                                                                                                    \
        }                                                                                                              \
    }

void Gateway::RealForwardingPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    printf("forward packet<%d>\n", packet.command());

    int others_count = packet.others_conn_id_size();
    if (others_count == 0) {
        // send packet to only current player
        uint32 conn_id = packet.user_conn_id();

        const std::string& str = packet.serialized();
        SendPacket(conn_id, packet.command(), str);
        return;
    }

    for (int i = 0; i < others_count; i++) {
        uint32             conn_id = packet.others_conn_id(i);
        const std::string& str = packet.serialized();
        SendPacket(conn_id, packet.command(), str);
    }
}

void Gateway::HandleClientLoginResponse(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    ClientGate::LoginResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid player login response packet\n");
        return;
    }

    if (pkt.result() == ClientGate::enumResultSucc) {
        const auto& user_info = pkt.basic_user_info();
        printf("user login success: %s %s\n", user_info.nick().c_str(), user_info.user_id().c_str());
        GetGateUserManager().ChangeUserType(packet.user_conn_id(), GU_TYPE_PLAYER, "", user_info);
    }
    RealForwardingPacket(conn, packet);
}

void Gateway::HandleGameInstanceList(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    DBGate::GameRoomListServer request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid game instance list packet");
        return;
    }

    printf("Recv %s room list from record server\n", request.game_name().c_str());
    LOG("received game instance list packet from RS");
    for (int i = 0; i < request.rooms_size(); i++) {
        auto& r = request.rooms(i);
        if (r.limit_max() == 0 || r.limit_min() == 0) {
            continue;
        }
        GameInstanceDesc inst = {-1, -1, r.desc(), 0, r.count(), r.limit_min(), r.limit_max(), r.default_carry()};
        printf("\t%s\n", r.desc().c_str());
        GetGameMgr().AddGame(request.game_name(), r.count(), inst);
    }
}

void Gateway::HandleSaveData(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    GatewayServer::SaveData request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid SaveData packet");
        return;
    }

    auto user = GetGateUserManager().GetUserById(packet.user_id());
    if (user != 0) {
        if (request.name() == "balance") {
            auto score = user->GetUserInfo().user_score();
            score += atoll(request.str().c_str());
            user->GetUserInfo().set_user_score(score);
        }
    }

    auto rs = GetGateUserManager().GetRecordServer();
    if (rs == 0) {
        LOG("record server is offline");
        return;
    }
    PB::ForwardingPacket tmp(packet);
    tmp.set_user_conn_id(conn->GetId());
    SendRawPacket(rs->GetConn(), tmp);
}

void Gateway::HandleSaveDataResponse(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    GatewayServer::SaveDataResponse request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid SaveDataResponse packet");
        return;
    }

    auto ls = GetGateUserManager().GetLogicServer(packet.user_conn_id());
    if (ls == 0 || ls->GetConn() == 0) {
        LOG("current logic server is offline");
        return;
    }
    SendRawPacket(ls->GetConn(), packet);
}
bool Gateway::PreHandleServerPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    bool result = true;
    switch (packet.command()) {
    case Protocol::CLIENT_LOGIN_RESPONSE:
        HandleClientLoginResponse(conn, packet);
        break;
    case Protocol::HEART_BEAT:
        break;
    case Protocol::GAME_INSTANCE_LIST:
        HandleGameInstanceList(conn, packet);
        break;
    case Protocol::SAVE_DATA:
        HandleSaveData(conn, packet);
        break;
    case Protocol::SAVE_DATA_RESPONSE:
        HandleSaveDataResponse(conn, packet);
        break;
    case Protocol::CLIENT_LEAVE_GAME:
        break;
    default:
        result = false;
    }
    return result;
}
void Gateway::HandleForwardingPacket(const ConnectionPtr& conn, const PB::ForwardingPacket& packet)
{
    if (PreHandleServerPacket(conn, packet)) {
        return;
    }
    RealForwardingPacket(conn, packet);
}

//////////////////////////////////////////////////////////////////////////

void Gateway::HandleHeartBeat(const ConnectionPtr& conn, const PB::Packet& packet)
{
    auto user = GetGateUserManager().GetAnyUser(conn->GetId());
    if (user != 0) {
        user->ResetDeadLine();
    }
}

void Gateway::HandleServerLogin(const ConnectionPtr& conn, const PB::Packet& packet)
{
    GatewayServer::LoginRequest request;

    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid server login packet, shutdown this connection");
        conn->Shutdown();
        return;
    }

    GatewayServer::EnumServerType type = request.server_type();
    std::string                   account = request.account() + std::to_string(type);
    std::string                   key = request.secure_key();

    std::string result = GetMD5((uint8*)account.c_str(), account.size());
    if (result != key) {
        LOG("invalid server login packet, wrong key, shutdown this connection");
        conn->Shutdown();
        return;
    }

    printf("%s server login\n", request.account().c_str());

    GetGateUserManager().ChangeUserType(
        conn->GetId(), type == GatewayServer::ST_GameServer ? GU_TYPE_GAME_SERVER : GU_TYPE_RECORD_SERVER,
        request.account());
}

void Gateway::HandleClientLogin(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::LoginRequest request;

    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client login packet, shutdown this connection");
        conn->Shutdown();
        return;
    }

    std::string mac = request.mac();
    std::string device_id = request.device_id();

    std::string        hash = mac + "P36J9FH3HF0fujweu9we9dcjn3488CRY0X47CH" + device_id;
    std::ostringstream ohash;
    ohash << fasthash64(hash.c_str(), hash.length(), 0);
    if (request.secure_key() != ohash.str()) {
        LOG("invalid client login packet, wrong secure key, shutdown this connection");
        conn->Shutdown();
        return;
    }

    std::string acc = request.account();
    std::string nick = request.nick();
    printf("[%s/%s] request to login\n", acc.c_str(), nick.c_str());

    Router::ForwardPacketToRS(conn->GetId(), packet, [&](const ConnectionPtr& conn, const PB::ForwardingPacket& pkt) {
        SendRawPacket(conn, pkt);
    });
}

void Gateway::HandleUserListRequest(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::GetOnlineUsers request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client get online users packet, shutdown this connection");
        conn->Shutdown();
        return;
    }

    auto                       vec = GetGateUserManager().GetOnlineUsers(request.start(), request.count());
    ClientGate::OnlineUserList resp;
    for (auto& v : vec) {
        ClientGate::BasicUserInfo* info = resp.add_users();
        *info = v.second->GetUserInfo();
    }
    SendPacket(conn, Protocol::ONLINE_USER_LIST, resp);
}

void Gateway::HandleAddFriend(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::AddFriendReqest request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client add friend packet, shutdown this connection");
        conn->Shutdown();
        return;
    }

    auto user = GetGateUserManager().GetUser(conn->GetId());
    if (user == 0) {
        return;
    }
    auto user_info = user->GetUserInfo();
    printf("%s request to add friend with: %s\n", user_info.user_id().c_str(), request.target_id().c_str());

    auto target = GetGateUserManager().GetUserById(request.target_id());
    if (target == 0) {
        // TODO
        printf("%s is not online now.\n", request.target_id().c_str());

        ClientGate::AddFriendConfirm request;
        request.set_target_id(request.target_id());
        request.set_result(ClientGate::NotOnline);
        SendPacket(conn, Protocol::ADD_FRIEND_CONFIRM, request);
        return;
    }
    ClientGate::BasicUserInfo* info = request.mutable_user();
    *info = target->GetUserInfo();
    SendPacket(target->GetConn(), Protocol::ADD_FRIEND_REQ, request);
}

void Gateway::HandleAddFriendConfirm(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::AddFriendConfirm request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client add friend confirm packet, shutdown this connection");
        conn->Shutdown();
        return;
    }

    auto user = GetGateUserManager().GetUser(conn->GetId());
    if (user == 0) {
        return;
    }

    auto target = GetGateUserManager().GetUserById(request.target_id());
    if (request.result() == ClientGate::Accepted) {
        // 1. �·���Ϣ
        ClientGate::BasicUserInfo* info = request.mutable_target_user();
        *info = user->GetUserInfo();

        // 2. ��¼�����ݿ�
        PB::Packet pkt(packet);
        request.SerializeToString(pkt.mutable_serialized());
        Router::ForwardPacketToRS(conn->GetId(), pkt, [&](const ConnectionPtr& conn, const PB::ForwardingPacket& pkt) {
            SendRawPacket(conn, pkt);
        });
    }

    if (target != 0) {
        SendPacket(target->GetConn(), Protocol::ADD_FRIEND_CONFIRM, request);
    }
}

void Gateway::HandleClientGetInstanceList(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::ClientGetInstanceListRequest request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client get game instance packet, shutdown this connection");
        conn->Shutdown();
        return;
    }
    SendGameList(conn, request.game_name());
}

GateUserPtr Gateway::GetLogicServerAndRoomInfo(const ConnectionPtr& conn, const std::string& name, uint32 room_id,
                                               GameInstanceDesc& info)
{
    uint32 logic_server_conn_id = GetGameMgr().GetLogicServerByIndex(name, room_id);
    if (logic_server_conn_id == -1) {
        logic_server_conn_id = GetGateUserManager().GetRandomLogicServer();
    }

    ClientGate::EnterGameResponse response;
    auto                          logic_server = GetGateUserManager().GetLogicServer(logic_server_conn_id);
    if (logic_server_conn_id == -1 || logic_server == 0) {
        LOG("no logic server is connected now");
        response.set_result(ClientGate::enumResultFail);
        SendPacket(conn, Protocol::CLIENT_ENTER_GAME_RESPONSE, response);
        return 0;
    }

    GetGameMgr().PlayerEnterGame(conn->GetId(), name, room_id, logic_server_conn_id);

    info = GetGameMgr().GetInstanceInfo(name, room_id);
    if (info.inst_id == -1) {
        auto id = GetGateUserManager().GetUserId(conn->GetId());
        LOG("player %s send invalid room id, kick it now", id.c_str());
        conn->Shutdown();
        return 0;
    }
    return logic_server;
}

void Gateway::PlayerEnterRoom(const ConnectionPtr& conn, ClientGate::EnterGameRequest& request)
{
    GameInstanceDesc info;
    auto             logic_server = GetLogicServerAndRoomInfo(conn, request.game_name(), request.room_id(), info);
    if (logic_server == 0) {
        return;
    }

    std::ostringstream ost;
    ost << info.min_enter_limit << "," << info.max_enter_limit << "," << info.default_carry << "," << info.desc;
    request.set_desc(ost.str());
    ForwardPacket(logic_server->GetConn(), Protocol::CLIENT_ENTER_GAME, conn->GetId(), request);
}

void Gateway::PlayerLookTable(const ConnectionPtr& conn, ClientGate::LookTable& request)
{
    GameInstanceDesc info;
    auto             logic_server = GetLogicServerAndRoomInfo(conn, request.game_name(), request.room_id(), info);
    if (logic_server == 0) {
        return;
    }

    std::ostringstream ost;
    ost << info.min_enter_limit << "," << info.max_enter_limit << "," << info.default_carry << "," << info.desc;
    request.set_desc(ost.str());
    ForwardPacket(logic_server->GetConn(), Protocol::CLIENT_LOOK_TABLE, conn->GetId(), request);
}

void Gateway::HandleLookTable(const ConnectionPtr& conn, const PB::Packet& packet)
{
    ClientGate::LookTable request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client look table packet");
        conn->Shutdown();
        return;
    }
    PlayerLookTable(conn, request);
}

void Gateway::HandleClientEnterGame(const ConnectionPtr& conn, const PB::Packet& packet)
{
#if !IS_DEBUG_VER
    CHECK_LOGIN(conn->GetId());
#endif  // !IS_DEBUG_VER

    ClientGate::EnterGameRequest request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client enter game packet");
        conn->Shutdown();
        return;
    }

    PlayerEnterRoom(conn, request);
}

inline ClientGate::EnumEnterGameResult ValidateEnterGameErrorCode(uint32 code)
{
    int c = std::abs((int)code);
    if (c >= -(int)(ClientGate::MAX_ENTER_GAME_RESULT)) {
        code = ClientGate::UNKNOWN_ERROR;
    }
    return (ClientGate::EnumEnterGameResult)code;
}
void Gateway::HandleQuickClientEnterGame(const ConnectionPtr& conn, const PB::Packet& packet)
{
#if !IS_DEBUG_VER
    CHECK_LOGIN(conn->GetId());
#endif  // IS_DEBUG_VER

    ClientGate::QuickEnterGameRequest request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("invalid client quick enter game packet");
        conn->Shutdown();
        return;
    }

    auto user = GetGateUserManager().GetUser(conn->GetId());
    if (user == 0) {
        LOG("[Gateway::HandleQuickClientEnterGame] Cannot find the user: %08x", conn->GetId());
        conn->Shutdown();
        return;
    }

    int64  gold = user->GetUserInfo().user_score();
    uint32 result = GetGameMgr().GetProperInstance(gold, request.game_name());
    do {
        if (!IS_VALID_INSTANCE(result)) {
            break;
        }

        auto info = GetGameMgr().GetInstanceInfo(request.game_name(), result);
        if (info.min_enter_limit == 0 || info.max_enter_limit == 0) {
            result = ClientGate::SERVER_CONFIG_ERROR;
            break;
        }

        if (gold >= info.max_enter_limit) {
            gold = info.max_enter_limit;
        }

        {
            ClientGate::QuickEnterGameResponse rsp;
            rsp.set_game_name(request.game_name());

            Common::GameInstanceClient* info = rsp.mutable_info();
            auto                        desc = GetGameMgr().GetInstanceInfo(request.game_name(), result);

            std::ostringstream ost;
            ost << desc.min_enter_limit << "," << desc.max_enter_limit << "," << desc.default_carry << "," << desc.desc;
            info->set_index(result);
            info->set_desc(ost.str());
            info->set_cur_player_count(desc.cur_player_count);
            info->set_max_player_count(desc.max_player_count);
            SendPacket(conn, Protocol::CLIENT_QUICK_ENTER_GAME_RESPONSE, rsp);
        }

        ClientGate::EnterGameRequest req;
        req.set_game_name(request.game_name());
        req.set_room_id(result);
        PlayerEnterRoom(conn, req);
        return;
    } while (0);

    ClientGate::EnterGameResponse rsp;
    rsp.set_result(ClientGate::enumResultFail);
    rsp.set_why(ValidateEnterGameErrorCode(result));
    SendRawPacket(conn, rsp);
}

void Gateway::HandleClientLeaveGame(const ConnectionPtr& conn, const PB::Packet& packet)
{
#if !IS_DEBUG_VER
    CHECK_LOGIN(conn->GetId());
#endif  // IS_DEBUG_VER

    UserLeaveGame(conn->GetId());
}

void Gateway::HandleClientGetInfo(const ConnectionPtr& conn, const PB::Packet& packet)
{
    Router::ForwardPacketToRS(conn->GetId(), packet, [&](const ConnectionPtr& conn, const PB::ForwardingPacket& pkt) {
        SendRawPacket(conn, pkt);
    });
}

bool Gateway::PreHandleClientPacket(const ConnectionPtr& conn, const PB::Packet& packet)
{
    bool result = true;
    switch (packet.command()) {
    case Protocol::HEART_BEAT:
        HandleHeartBeat(conn, packet);
        break;
    case Protocol::SERVER_LOGIN_REQUEST:
        HandleServerLogin(conn, packet);
        break;
    case Protocol::CLIENT_LOGIN_REQUEST:
        HandleClientLogin(conn, packet);
        break;

    // Online User List
    case Protocol::ONLINE_USER_LIST_REQUEST:
        HandleUserListRequest(conn, packet);
        break;

    // Friends
    case Protocol::ADD_FRIEND_REQ:
        HandleAddFriend(conn, packet);
        break;
    case Protocol::ADD_FRIEND_CONFIRM:
        HandleAddFriendConfirm(conn, packet);
        break;

    case Protocol::CLIENT_GET_INSTANCE_LIST:
        HandleClientGetInstanceList(conn, packet);
        break;
    case Protocol::CLIENT_LOOK_TABLE:
        HandleLookTable(conn, packet);
        break;
    case Protocol::CLIENT_ENTER_GAME:
        HandleClientEnterGame(conn, packet);
        break;
    case Protocol::CLIENT_QUICK_ENTER_GAME:
        HandleQuickClientEnterGame(conn, packet);
        break;
    case Protocol::CLIENT_LEAVE_GAME:
        HandleClientLeaveGame(conn, packet);
        break;

    case Protocol::CLIENT_GET_USERINFO:
        HandleClientGetInfo(conn, packet);
        break;
    default:
        result = false;
    }
    return result;
}
void Gateway::HandleClientPacket(const ConnectionPtr& conn, const PB::Packet& packet)
{
    if (PreHandleClientPacket(conn, packet)) {
        printf("recv client packet: %d, processed by Gateway\n", packet.command());
        return;
    }

    printf("recv client packet: %d, need forward to logic server\n", packet.command());
    Router::ForwardPacketToLS(conn->GetId(), packet, [&](const ConnectionPtr& conn, const PB::ForwardingPacket& pkt) {
        SendRawPacket(conn, pkt);
    });
}
