#include "Gateway.h"

#include "../ServerLib/TcpConnection.h"

#include "GameMgr.h"
#include "GateUser.h"


#include "ClientGate.pb.h"
#include "Common.pb.h"
#include "Gateway.pb.h"
#include "Protocol.pb.h"


bool Gateway::CheckServerDisconnect(uint32 user_conn_id)
{
    auto logic_serv = GetGateUserManager().GetLogicServer(user_conn_id);
    auto record_serv = GetGateUserManager().GetRecordServer(user_conn_id);
    if (logic_serv || record_serv) {
        if (logic_serv) {
            GetGameMgr().LogicServerDisconnect(logic_serv->GetSig(), logic_serv->GetConn()->GetId());
        }
        GetGateUserManager().RemoveUser(user_conn_id);
        return true;
    }
    return false;
}

void Gateway::UserLeaveGame(uint32 user_conn_id)
{
    auto game = GetGateUserManager().GetLogicServerFromUserConnId(user_conn_id);
    if (game != 0) {
        ClientGate::LeaveGameRequest pkt;
        ForwardPacket(game, Protocol::CLIENT_LEAVE_GAME, user_conn_id, pkt);
    }

    auto user = GetGateUserManager().GetUser(user_conn_id);
    if (user != 0) {
        auto room_id = user->GetRoomId();
        if (room_id != -1) {
            printf("%d leave game: %d %s\n", user_conn_id, room_id, user->GetCurGame().c_str());

            GetGameMgr().PlayerLeaveGame(user_conn_id, user->GetCurGame(), room_id);
        }
    }
}

void Gateway::UserDisconnect(uint32 user_conn_id)
{
    // Logic or Record Server disconnect
    if (CheckServerDisconnect(user_conn_id)) {
        return;
    }

    UserLeaveGame(user_conn_id);

    // notify all watchers
    auto user_id = GetGateUserManager().GetUserId(user_conn_id);
    GetGateUserManager().NotifyWatcher(user_conn_id, [&](uint32 watcher_conn_id) {
        auto watcher = GetGateUserManager().GetUser(watcher_conn_id);
        if (watcher == 0) {
            return;
        }
        auto watcher_conn = watcher->GetConn();
        if (watcher_conn == 0) {
            return;
        }

        ClientGate::UserDisconnect pkt;
        pkt.set_user_id(user_id);
        SendPacket(watcher_conn, Protocol::USER_DISCONNECTED_TO_CL, pkt);
    });

    auto user = GetGateUserManager().GetAnyUser(user_conn_id);
    if (user != 0) {
        user->Destroy();
        GetGateUserManager().RemoveUser(user_conn_id);
    }
}

void Gateway::SendGameList(const ConnectionPtr& conn, const std::string& game_name)
{
    Common::GameInstanceListClient pkt;
    pkt.set_game_name(game_name);
    auto func = [&](uint32 index, const GameInstanceDesc& desc) {
        Common::GameInstanceClient* instance = pkt.add_instances();
        instance->set_index(index);

        std::ostringstream ost;
        ost << desc.min_enter_limit << "," << desc.max_enter_limit << "," << desc.default_carry << "," << desc.desc;
        instance->set_desc(ost.str());
        instance->set_cur_player_count(desc.cur_player_count);
        instance->set_max_player_count(desc.max_player_count);
    };
    GetGameMgr().EnumGame(game_name, std::bind(func, std::placeholders::_1, std::placeholders::_2));
    SendPacket(conn, Protocol::GAME_INSTANCE_LIST, pkt);
}
