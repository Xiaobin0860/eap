#include "GameMgr.h"

#include "GateUser.h"

#include "ClientGate.pb.h"

GameInstanceMgr::GameInstanceMgr()
    : index_(0)
{
}

void GameInstanceMgr::AddInstance(int inst_count, const GameInstanceDesc& inst)
{
    for (int i = 0; i < inst_count; i++, index_++) {
        GameInstanceDesc tmp(inst);
        tmp.inst_id = index_;
        instances_[index_] = tmp;
    }
}

GameInstanceDesc GameInstanceMgr::GetInstanceInfo(uint32 index)
{
    auto it = instances_.find(index);
    if (it == instances_.end()) {
        return EmptyInstance;
    }
    return it->second;
}

void GameInstanceMgr::EnumInstance(const GameInstanceFunc& func)
{
    for (auto& i : instances_) {
        func(i.first, i.second);
    }
}

std::string GameInstanceMgr::GetDesc(uint32 index)
{
    auto it = instances_.find(index);
    if (it == instances_.end()) {
        return "";
    }
    return it->second.desc;
}

uint32 GameInstanceMgr::GetLogicServerByIndex(uint32 index)
{
    auto it = instances_.find(index);
    if (it == instances_.end()) {
        return -1;
    }
    return it->second.logic_server_conn_id;
}

void GameInstanceMgr::LogicServerDisconnect(uint32 gs_id)
{
    for (auto& i : instances_) {
        if (i.second.logic_server_conn_id == gs_id) {
            i.second.logic_server_conn_id = -1;
            i.second.cur_player_count = i.second.max_player_count = 0;
        }
    }
}

uint32 GameInstanceMgr::PlayerEnterGame(uint32 index, uint32 gs_id)
{
    auto it = instances_.find(index);
    if (it == instances_.end()) {
        return ClientGate::NO_SUCH_INSTANCE;
    }
    it->second.cur_player_count++;
    it->second.logic_server_conn_id = gs_id;
    return it->second.inst_id;
}

void GameInstanceMgr::PlayerLeaveGame(uint32 index)
{
    auto it = instances_.find(index);
    if (it == instances_.end()) {
        return;
    }
    if (it->second.cur_player_count > 0) {
        it->second.cur_player_count--;
    }
    if (it->second.cur_player_count == 0) {
        it->second.logic_server_conn_id = -1;
    }
}

std::vector<GameInstanceDesc> GameInstanceMgr::GetAllInstances()
{
    std::vector<GameInstanceDesc> vec;
    for (auto& i : instances_) {
        vec.push_back(i.second);
    }
    return vec;
}
uint32 GameInstanceMgr::GetInstance(int64 player_gold)
{
    auto instances = GetAllInstances();
    if (instances.empty()) {
        return ClientGate::NO_SUCH_INSTANCE;
    }
    std::sort(instances.begin(), instances.end(), [&](const GameInstanceDesc& lhs, const GameInstanceDesc& rhs) {
        return lhs.max_enter_limit > rhs.max_enter_limit;
    });
    for (auto it = instances.begin(); it != instances.end(); it++) {
        if (player_gold > it->min_enter_limit) {
            return it->inst_id;
        }
    }
    return ClientGate::NOT_ENOUGH_MONEY;
}

void GameMgr::AddGame(const std::string& game, int inst_count, const GameInstanceDesc& inst)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it == games_.end()) {
        games_[game] = GameInstanceMgr();
    }

    GameInstanceMgr& mgr = games_[game];
    mgr.AddInstance(inst_count, inst);
}

void GameMgr::EnumGame(const std::string& game, const GameInstanceFunc& func)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it != games_.end()) {
        it->second.EnumInstance(func);
    }
}

GameInstanceDesc GameMgr::GetInstanceInfo(const std::string& game, uint32 index)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it != games_.end()) {
        return it->second.GetInstanceInfo(index);
    }
    return EmptyInstance;
}

uint32 GameMgr::GetLogicServerByIndex(const std::string& game, uint32 index)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it == games_.end()) {
        return -1;
    }
    return it->second.GetLogicServerByIndex(index);
}

void GameMgr::LogicServerDisconnect(const std::string& game, uint32 gs_id)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it == games_.end()) {
        return;
    }
    it->second.LogicServerDisconnect(gs_id);
}

uint32 GameMgr::PlayerEnterGame(uint32 conn_id, const std::string& game, uint32 index, uint32 gs_id)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it == games_.end()) {
        return ClientGate::NO_SUCH_GAME;
    }

    auto user = GetGateUserManager().GetUser(conn_id);
    if (user != 0) {
        user->SetCurGame(game);
        user->SetGameServerId(gs_id);
        user->SetRoomId(index);
    }

    return it->second.PlayerEnterGame(index, gs_id);
}

void GameMgr::PlayerLeaveGame(uint32 conn_id, const std::string& game, uint32 index)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it != games_.end()) {
        auto user = GetGateUserManager().GetUser(conn_id);
        if (user != 0) {
            user->SetCurGame("");
            user->SetGameServerId(-1);
            user->SetRoomId(-1);
        }

        it->second.PlayerLeaveGame(index);
    }
}

uint32 GameMgr::GetProperInstance(int64 gold, const std::string& game)
{
    Lock l(mutex_);
    auto it = games_.find(game);
    if (it == games_.end()) {
        return ClientGate::NO_SUCH_GAME;
    }
    auto&  mgr = it->second;
    uint32 instance_id = mgr.GetInstance(gold);
    bool   b = IS_VALID_INSTANCE(instance_id);
    return instance_id;
}
