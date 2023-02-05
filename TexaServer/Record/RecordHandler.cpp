#include "RecordClient.h"
#include "RedisClient.h"

#include "ClientGate.pb.h"
#include "Gateway.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"


#include "PacketDataCache.h"
#include "UUIDMgr.h"


#include "../ServerLib/md5.h"

void RecordClient::Handler(const PB::ForwardingPacket& packet)
{
    int    type = PKT_TYPE_NULL;
    uint32 cmd = packet.command();

    if (cmd < Protocol::SERVER_LOGIN_REQUEST) {
        type = PKT_TYPE_COMMON;
        cmd -= Protocol::USER_DISCONNECTED_TO_CL;
    } else if (cmd < Protocol::CLIENT_LOGIN_REQUEST) {
        type = PKT_TYPE_GATEWAY;
        cmd -= Protocol::SERVER_LOGIN_REQUEST;
    } else if (cmd < Protocol::DEAL_TO_CLIENT) {
        type = PKT_TYPE_CLIENT;
        cmd -= Protocol::CLIENT_LOGIN_REQUEST;
    } else {
        type = PKT_TYPE_TEXASPOKER;
        cmd -= Protocol::DEAL_TO_CLIENT;
    }

    if (cmd >= MAX_PKT_TYPES)
        return;

    auto handler = phandler_[type][cmd];
    if (handler)
        handler(packet);
}

void RecordClient::LoginHandler(const PB::ForwardingPacket& packet)
{
    ClientGate::LoginRequest request;
    if (!request.ParseFromString(packet.serialized())) {
        LOG("Parse LoginRequest failed");
        return;
    }

    auto  login_type = request.login_type();
    auto& account = request.account();
    auto& password = request.password();
    auto& nick = request.nick();
    auto  gender = request.gender();
    auto  device_type = request.device_type();
    auto& device_id = request.device_id();
    auto& device_token = request.device_token();
    auto& mac = request.mac();
    auto& secure_key = request.secure_key();
    auto& channel = request.channel();
    auto  version = request.version();
    auto  phone_no = request.has_phone_no() ? request.phone_no() : "";

    auto md5_pwd = password;
    for (int i = 0; i < 3; i++) {
        md5_pwd = GetMD5((md5byte*)md5_pwd.c_str(), md5_pwd.length());

        std::string hex_pwd;
        std::for_each(md5_pwd.begin(), md5_pwd.end(), [&hex_pwd](const char c) {
            char buf[3] = {0};
            sprintf(buf, "%02X", (unsigned char)c);
            hex_pwd += buf;
        });

        md5_pwd = hex_pwd;
    }

    auto uuid = GetUUIDMgr().Get(account);
    if (login_type == ClientGate::enumLoginTypeRegisterNewUser) {
        if (Proc_Registe(uuid, account, md5_pwd, nick, gender) != -1) {
            login_type = ClientGate::enumLoginTypeRegisterAccount;
            GetUUIDMgr().Add(account, uuid);
        }
    }

#ifdef WIN32
    printf("[%s: %s, %s] request login\n", uuid.c_str(), account.c_str(), password.c_str(),
           login_type == ClientGate::enumLoginTypeRegisterAccount ? "login" : "regist");
#endif
    LOG("[%s: %s, %s] request login", uuid.c_str(), account.c_str(), password.c_str());
    if (login_type == ClientGate::enumLoginTypeRegisterAccount) {
        GetPacketDataCacheMgr().Push(uuid, REQUEST_TYPE_LOGIN, packet.user_conn_id(), account, md5_pwd);
        Proc_Login(uuid, account, md5_pwd);
    }
}

void RecordClient::SaveDataHandler(const PB::ForwardingPacket& packet)
{
    GatewayServer::SaveData request;
    if (!request.ParseFromString(packet.serialized()))
        return;

    auto& uuid = packet.user_id();
    auto  conn_id = packet.user_conn_id();
    auto  name = request.name();
    auto  str = request.has_str() ? request.str() : "";

    GetPacketDataCacheMgr().Push(uuid, REQUEST_TYPE_SAVEDATA, conn_id, name, str);

    redis_->Get("HMGET", game_name_, TBL_USER, uuid, "uuid", "desc");
}

void RecordClient::UseItemHandler(const PB::ForwardingPacket& packet)
{
    ClientGate::UseItem request;
    if (!request.ParseFromString(packet.serialized()))
        return;

    auto& uuid = packet.user_id();
    auto  conn_id = packet.user_conn_id();
}

void RecordClient::UpdateFriendHandler(const PB::ForwardingPacket& packet)
{
    ClientGate::UpdateFriend request;
    if (!request.ParseFromString(packet.serialized()))
        return;

    auto& uuid = packet.user_id();
    auto  conn_id = packet.user_conn_id();
    auto& friend_id = request.friend_id();
    auto  flag = request.flag();

    if (flag == 0) {
        GetPacketDataCacheMgr().Push(uuid, REQUEST_TYPE_UPDATEFRIENDS, conn_id, friend_id, flag);
        SaveAddFriend(uuid, conn_id);
    } else if (flag == 1) {
        GetPacketDataCacheMgr().Push(uuid, REQUEST_TYPE_UPDATEFRIENDS, conn_id, friend_id, flag);
        SaveDelFriend(uuid, conn_id);
    } else
        return;
}

void RecordClient::GetUserInfoHandler(const PB::ForwardingPacket& packet)
{
    ClientGate::ClientGetUserInfo request;
    if (!request.ParseFromString(packet.serialized()))
        return;

    auto& uuid = packet.user_id();
    auto  conn_id = packet.user_conn_id();

    auto& uuid_ = request.user_id();

    GetPacketDataCacheMgr().Push(uuid_, REQUEST_TYPE_USERINFO, conn_id, uuid);

    redis_->Get("HMGET", game_name_, TBL_USER, uuid_, "uuid", "desc");
}
