#include <stdio.h>

#include <unordered_map>

#include "../ServerLib/TcpClient.h"
#include "../ServerLib/fasthash.h"

#include "ClientGate.pb.h"
#include "Common.pb.h"
#include "Packet.pb.h"
#include "Protocol.pb.h"


using namespace Protocol;
using namespace ClientGate;

TcpClientPtr client;

const char* device_name = "MI 2S";

std::string                                            cur_game_name_;
std::unordered_map<uint32, Common::GameInstanceClient> game_instances_;

void SendPacket(const PB::Packet& pkt)
{
    uint32 size = pkt.ByteSize();
    uint8* buf = (uint8*)alloca(size + 4);
    memcpy(buf, &size, 4);
    pkt.SerializeToArray(buf + 4, size);
    client->Send(buf, size + 4);
}
template <typename T>
void SendPacket(Protocol::ClientGateProtocol cmd, const T& pkt)
{
    PB::Packet packet;
    packet.set_command(cmd);
    pkt.SerializeToString(packet.mutable_serialized());
    SendPacket(packet);
}

void Login()
{
    std::string mac_("mlwwl");
    std::string user = mac_ + "@test.me";
    std::string deviceid = "";

    std::string        strHash = mac_ + "P36J9FH3HF0fujweu9we9dcjn3488CRY0X47CH" + deviceid;
    std::ostringstream ohash;
    ohash << fasthash64(strHash.c_str(), strHash.length(), 0);

    LoginRequest request;
    request.set_login_type(enumLoginTypeRegisterNewUser);
    request.set_account(user);
    request.set_password(mac_);
    request.set_nick(device_name);
    request.set_gender(enumGenderMale);
    request.set_device_type(enumDeviceTypeAndroid);
    request.set_device_id(deviceid);
    request.set_mac(mac_);
    request.set_channel("unknown");
    request.set_secure_key(ohash.str().c_str());
    request.set_version(1000);

    SendPacket(Protocol::CLIENT_LOGIN_REQUEST, request);
}

void GetUsers()
{
    GetOnlineUsers request;
    request.set_start(0);
    request.set_count(20);
    SendPacket(Protocol::ONLINE_USER_LIST_REQUEST, request);
}

void GetList()
{
    ClientGetInstanceListRequest request;
    request.set_game_name("TexasPoker");
    request.set_type(1);
    SendPacket(Protocol::CLIENT_GET_INSTANCE_LIST, request);
}

void Fold()
{
    UserFold request;
    SendPacket(Protocol::CLIENT_FOLD, request);
}

void QuickEnterGame(const std::string& game_name)
{
    QuickEnterGameRequest request;
    request.set_game_name(game_name);
    SendPacket(Protocol::CLIENT_QUICK_ENTER_GAME, request);
}

void EnterGame(const std::string& game_name, uint32 index)
{
    EnterGameRequest request;
    request.set_game_name(game_name);
    request.set_room_id(index);
    SendPacket(Protocol::CLIENT_ENTER_GAME, request);
}

void LookGame(const std::string& game_name, uint32 index)
{
    LookTable look;
    look.set_game_name(game_name);
    look.set_room_id(index);
    SendPacket(Protocol::CLIENT_LOOK_TABLE, look);
}

void GetUserInfo(const std::string& uuid)
{
    ClientGetUserInfo request;
    request.set_user_id(uuid);
    SendPacket(Protocol::CLIENT_GET_USERINFO, request);
}

void LeaveGame()
{
    LeaveGameRequest request;
    SendPacket(Protocol::CLIENT_LEAVE_GAME, request);
}

void AddFriend(const std::string& id)
{
    AddFriendReqest req;
    req.set_target_id(id);
    SendPacket(Protocol::ADD_FRIEND_REQ, req);
}

void LookTable1()
{
    LookTable req;
    req.set_room_id(1);
    req.set_game_name("TexasPoker");
    req.set_desc("");
    SendPacket(Protocol::CLIENT_LOOK_TABLE, req);
}

void HandleLoginResponse(const PB::Packet& packet)
{
    ClientGate::LoginResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }

    GetList();
    EnterGame("TexasPoker", 1);
    LookGame("TexasPoker", 1);
    // GetUserInfo("02b165ac-73d9-42b5-8407-66e8d82b7a5a");
    // AddFriend("8739368c-5e99-4118-9d37-ebdecc2d71e4");
}

void HandleInstanceList(const PB::Packet& packet)
{
    Common::GameInstanceListClient pkt;

    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }

    cur_game_name_ = pkt.game_name();
    printf("%s\n", cur_game_name_.c_str());
    for (int i = 0; i < pkt.instances_size(); i++) {
        Common::GameInstanceClient* instance = pkt.mutable_instances(i);
        game_instances_[instance->index()] = *instance;

        printf("\t%04d: %s %d/%d\n", instance->index(), instance->desc().c_str(), instance->cur_player_count(),
               instance->max_player_count());
    }

    QuickEnterGame(cur_game_name_);
    // Fold();
    // EnterGame("TexasPoker", 100000);
}

void HandleEnterResponse(const PB::Packet& packet)
{
    ClientGate::EnterGameResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("result : %d \n", pkt.result());
    printf("Gameing		: %d \n", pkt.table_info().gameing());
    printf("ButtonPlayer		: %d \n", pkt.table_info().buttonplayer());
    printf("SmallPlayer		: %d \n", pkt.table_info().smallplayer());
    printf("BigPlayer		: %d \n", pkt.table_info().bigplayer());
    for (int i = 0; i != pkt.table_info().downcards_size(); ++i)
        printf("DownCards		: %d \n", pkt.table_info().downcards(i));
    printf("CurMaxBet		: %d \n", pkt.table_info().curmaxbet());
    printf("Pot		: %d \n", pkt.table_info().pot());
    printf("CurPlayer		: %d \n", pkt.table_info().curplayer());
    printf("main_pool				: %d \n", pkt.table_info().main_pool());
    printf("timer				: %d \n", pkt.table_info().timer());

    for (int i = 0; i != pkt.user_info_size(); ++i) {
        printf("Uid				: %s \n", pkt.user_info(i).user_base().user_id().c_str());
        printf("nick			: %s \n", pkt.user_info(i).user_base().nick().c_str());
        printf("avatar			: %s \n", pkt.user_info(i).user_base().avatar().c_str());
        printf("gender			: %d \n", pkt.user_info(i).user_base().gender());
        printf("user_score		: %lld \n", pkt.user_info(i).user_base().user_score());
        printf("experience		: %lld \n", pkt.user_info(i).user_base().experience());

        printf("Uid				: %s \n", pkt.user_info(i).user_table().uid().c_str());
        printf("money				: %d \n", pkt.user_info(i).user_table().money());
        for (int j = 0; j != pkt.user_info(i).user_table().owncard_size(); ++j)
            printf("owncard				: %d \n", pkt.user_info(i).user_table().owncard(j));
        for (int j = 0; j != pkt.user_info(i).user_table().sidepool_size(); ++j)
            printf("sidepool				: %d \n", pkt.user_info(i).user_table().sidepool(j));
        printf("curbet				: %d \n", pkt.user_info(i).user_table().curbet());
        printf("totalbet				: %d \n", pkt.user_info(i).user_table().totalbet());
        printf("flod				: %d \n", pkt.user_info(i).user_table().flod());
        printf("allin				: %d \n", pkt.user_info(i).user_table().allin());
        printf("ingameing				: %d \n", pkt.user_info(i).user_table().ingameing());
    }
}

void HandleOtherEnterResponse(const PB::Packet& packet)
{
    ClientGate::OtherEnterGameResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("result : %d \n", pkt.result());
    printf("Uid				: %s \n", pkt.user_info().user_base().user_id().c_str());
    printf("nick			: %s \n", pkt.user_info().user_base().nick().c_str());
    printf("avatar			: %s \n", pkt.user_info().user_base().avatar().c_str());
    printf("gender			: %d \n", pkt.user_info().user_base().gender());
    printf("user_score		: %lld \n", pkt.user_info().user_base().user_score());
    printf("experience		: %lld \n", pkt.user_info().user_base().experience());
}

void HandleDeal(const PB::Packet& packet)
{
    ClientGate::DealToUser pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("Card_a				: %d \n", pkt.card_a());
    printf("Card_b				: %d \n", pkt.card_b());
    printf("button_user_id		: %s \n", pkt.button_user_id().c_str());
    printf("small_user_id		: %s \n", pkt.small_user_id().c_str());
    printf("big_user_id			: %s \n", pkt.big_user_id().c_str());
    printf("start_user_id		: %s \n", pkt.start_user_id().c_str());
    printf("small_stakes		: %d \n", pkt.small_stakes());
    printf("big_stakes			: %d \n", pkt.big_stakes());
}

void HandleFlodRes(const PB::Packet& packet)
{
    ClientGate::UserFlodResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("result : %d \n", pkt.result());

    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleOtherFlod(const PB::Packet& packet)
{
    ClientGate::OtherUserFlod pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("user_id		: %s \n", pkt.user_id().c_str());

    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleCallRes(const PB::Packet& packet)
{
    ClientGate::UserCallResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("result : %d \n", pkt.result());
    printf("money		: %d \n", pkt.money());
    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleOtherCall(const PB::Packet& packet)
{
    ClientGate::OtherUserCall pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("user_id		: %s \n", pkt.user_id().c_str());
    printf("money		: %d \n", pkt.money());
    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleRaiseRes(const PB::Packet& packet)
{
    ClientGate::UserRaiseResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("result : %d \n", pkt.result());
    printf("money		: %d \n", pkt.money());
    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleOtherRaise(const PB::Packet& packet)
{
    ClientGate::OtherUserRaise pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("user_id		: %s \n", pkt.user_id().c_str());
    printf("money		: %d \n", pkt.money());
    printf("next_user_id		: %s \n", pkt.next_user_id().c_str());
}

void HandleDownCard(const PB::Packet& packet)
{
    ClientGate::CardToUser pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("start_user_id		: %s \n", pkt.start_user_id().c_str());
    for (int i = 0; i != pkt.card_size(); ++i)
        printf("card		: %d \n", pkt.card(i));
}

void HandleSettle(const PB::Packet& packet)
{
    ClientGate::SettleToUser pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
}

void HandleUserInfo(const PB::Packet& packet)
{
    ClientGate::ClientGetUserInfoResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game instance list packet\n");
        return;
    }
    printf("%s\n", __FUNCTION__);
    printf("%s\n", pkt.basic_user_info().user_id().c_str());
}

void HandleUserList(const PB::Packet& packet)
{
    ClientGate::OnlineUserList pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        printf("invalid game user list packet\n");
        return;
    }
    printf("%s\n", __FUNCTION__);
    for (int i = 0; i < pkt.users_size(); i++) {
        auto& u = pkt.users(i);
        printf("%s\n", u.user_id().c_str());
    }
}

void HandleAddFriend(const PB::Packet& packet)
{
    ClientGate::AddFriendReqest pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        return;
    }
    printf("%s\n", __FUNCTION__);
    printf("%s request to add friend\n", pkt.target_id().c_str());
}

void HandleAddFriendConfirm(const PB::Packet& packet)
{
    ClientGate::AddFriendConfirm pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        return;
    }
    printf("%s\n", __FUNCTION__);
    printf("add friend confirm: %d\n", pkt.result());
}

void HandleQuickEnterGame(const PB::Packet& packet)
{
    ClientGate::QuickEnterGameResponse pkt;
    if (!pkt.ParseFromString(packet.serialized())) {
        return;
    }
    printf("%s\n", __FUNCTION__);
}

void Dispatch(uint32 conn_id, const uint8* buf, uint32 len)
{
    PB::Packet packet;
    if (!packet.ParseFromArray(buf, len)) {
        return;
    }
    printf("recv command :%d \n", packet.command());
    switch (packet.command()) {
    case Protocol::CLIENT_LOGIN_RESPONSE:
        printf("recv login response\n");
        HandleLoginResponse(packet);
        break;
    case Protocol::GAME_INSTANCE_LIST:
        printf("recv game instance list\n");
        HandleInstanceList(packet);
        break;
    case Protocol::CLIENT_ENTER_GAME_RESPONSE:
        printf("enter game response.\n");
        HandleEnterResponse(packet);
        break;
    case Protocol::CLIENT_OTHER_ENTER_GAME:
        printf("other enter game response.\n");
        HandleOtherEnterResponse(packet);
        break;
    case Protocol::DEAL_TO_CLIENT:
        printf("DEAL_TO_CLIENT.\n");
        HandleDeal(packet);
        break;
    case Protocol::CLIENT_FOLD_RESPONSE:
        printf("CLIENT_FOLD_RESPONSE \n");
        HandleFlodRes(packet);
        break;
    case Protocol::CLIENT_OTHER_FLOD:
        printf("CLIENT_OTHER_FLOD \n");
        HandleOtherFlod(packet);
        break;
    case Protocol::CLIENT_CALL_RESPONSE:
        printf("CLIENT_CALL_RESPONSE \n");
        HandleCallRes(packet);
        break;
    case Protocol::CLIENT_OTHER_CALL:
        printf("CLIENT_OTHER_CALL \n");
        HandleOtherCall(packet);
        break;
    case Protocol::CLIENT_RAISE_RESPONSE:
        printf("CLIENT_RAISE_RESPONSE \n");
        HandleRaiseRes(packet);
        break;
    case Protocol::CLIENT_OTHER_RAISE:
        printf("CLIENT_OTHER_RAISE \n");
        HandleOtherRaise(packet);
        break;
    case Protocol::CARD_TO_CLIENT:
        printf("CARD_TO_CLIENT \n");
        HandleDownCard(packet);
        break;
    case Protocol::SETTLE_TO_CLIENT:
        printf("SETTLE_TO_CLIENT \n");
        HandleSettle(packet);
        break;
    case Protocol::CLIENT_GET_USERINFO_RESPONSE:
        printf("CLIENT_GET_USERINFO_RESPONSE \n");
        HandleUserInfo(packet);
        break;
    case Protocol::ONLINE_USER_LIST:
        printf("ONLINE_USER_LIST \n");
        HandleUserList(packet);
        break;
    case Protocol::ADD_FRIEND_REQ:
        printf("ADD_FRIEND_CONFIRM \n");
        HandleAddFriend(packet);
        break;
    case Protocol::ADD_FRIEND_CONFIRM:
        printf("ADD_FRIEND_CONFIRM \n");
        HandleAddFriendConfirm(packet);
        break;
    case Protocol::CLIENT_QUICK_ENTER_GAME_RESPONSE:
        printf("CLIENT_QUICK_ENTER_GAME_RESPONSE \n");
        HandleQuickEnterGame(packet);
        break;
    }
}

#include "Frame.inl"

int main()
{
    IoService ios;

    client.reset(new TcpClient(ios));
    client->SetCallBacks(GetCallBacks());

    ConnectToGate();

    ios.run();
}
