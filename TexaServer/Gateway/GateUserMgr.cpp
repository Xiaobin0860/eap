#include "GateUser.h"

#include "../ServerLib/ServerCommon.h"
#include "../ServerLib/TcpConnection.h"

void GateUserManager::AddUser(const ConnectionPtr& conn)
{
    GateUserPtr gu(new GateUser(conn));
    gu->Init();

    Lock l(mutex_);
    unknown_users_[conn->GetId()] = gu;
}

bool GateUserManager::ChangeUserType(uint32 conn_id, GateUserType type, const std::string& sig,
                                     const ClientGate::BasicUserInfo& info)
{
    Lock l(mutex_);
    auto it = unknown_users_.find(conn_id);
    if (it == unknown_users_.end()) {
        return false;
    }

    const GateUserPtr& gu = it->second;
    if (type == GU_TYPE_GAME_SERVER) {
        gu->SetSig(sig);
        gu->RemoveDeadLine();
        logic_servers_[conn_id] = gu;
    } else if (type == GU_TYPE_RECORD_SERVER) {
        gu->RemoveDeadLine();
        record_servers_[conn_id] = gu;
    } else {
        game_users_[conn_id] = gu;
        SetUserInfo(conn_id, info);
    }
    unknown_users_.erase(it);
    return true;
}

void GateUserManager::RemoveUser(uint32 conn_id)
{
    Lock l(mutex_);
    {
        auto it = game_users_.find(conn_id);
        if (it != game_users_.end()) {
            auto u = it->second;
            if (u) {
                conn_id_map_.erase(u->GetUserInfo().user_id());
            }
        }
    }
    record_servers_.erase(conn_id);
    logic_servers_.erase(conn_id);
    unknown_users_.erase(conn_id);
    game_users_.erase(conn_id);
}

GateUserPtr GateUserManager::GetAnyUser(uint32 conn_id)
{
    Lock l(mutex_);
    {
        auto it = game_users_.find(conn_id);
        if (it != game_users_.end()) {
            return it->second;
        }
    }
    {
        auto it = unknown_users_.find(conn_id);
        if (it != unknown_users_.end()) {
            return it->second;
        }
    }
    return 0;
}

void GateUserManager::SetUserInfo(uint32 conn_id, const ClientGate::BasicUserInfo& info)
{
    auto it = game_users_.find(conn_id);
    if (it != game_users_.end()) {
        auto& user = it->second;
        user->SetUid(info.user_id());
        user->SetUserInfo(info);
        user->SetStatus(GU_STATUS_IDLE);
        conn_id_map_[info.user_id()] = conn_id;
    }
}

GateUserPtr GateUserManager::GetRecordServerNoLock(uint32 conn_id)
{
    auto it = record_servers_.find(conn_id);
    if (it != record_servers_.end()) {
        return it->second;
    }
    return 0;
}
GateUserPtr GateUserManager::GetRecordServer(uint32 conn_id)
{
    Lock l(mutex_);
    return GetRecordServerNoLock(conn_id);
}
GateUserPtr GateUserManager::GetRecordServer()
{
    Lock l(mutex_);
    if (record_servers_.empty()) {
        return 0;
    }
    return record_servers_.begin()->second;
}

GateUserPtr GateUserManager::GetLogicServerNoLock(uint32 conn_id)
{
    auto it = logic_servers_.find(conn_id);
    if (it != logic_servers_.end()) {
        return it->second;
    }
    return 0;
}
GateUserPtr GateUserManager::GetLogicServer(uint32 conn_id)
{
    Lock l(mutex_);
    return GetLogicServerNoLock(conn_id);
}

uint32 GateUserManager::GetRandomLogicServer()
{
    Lock l(mutex_);
    if (logic_servers_.empty()) {
        return -1;
    }
    int  index = rand() % logic_servers_.size();
    auto it = logic_servers_.begin();
    std::advance(it, index);
    return it->first;
}

GateUserPtr GateUserManager::GetUserNoLock(uint32 conn_id)
{
    auto it = game_users_.find(conn_id);
    if (it != game_users_.end()) {
        return it->second;
    }
    return 0;
}
GateUserPtr GateUserManager::GetUser(uint32 conn_id)
{
    Lock l(mutex_);
    return GetUserNoLock(conn_id);
}

std::string GateUserManager::GetUserId(uint32 conn_id)
{
    GateUserPtr user = GetUser(conn_id);
    if (user == 0) {
        return std::string("");
    }
    return user->GetUid();
}

GateUserPtr GateUserManager::GetUserById(const std::string& user_id)
{
    Lock l(mutex_);
    auto it = conn_id_map_.find(user_id);
    if (it == conn_id_map_.end()) {
        return 0;
    }
    return GetUserNoLock(it->second);
}

ConnectionPtr GateUserManager::GetLogicServerFromUserConnId(uint32 conn_id)
{
    Lock l(mutex_);
    auto user = GetUserNoLock(conn_id);
    if (user == 0) {
        return 0;
    }

    auto game = GetLogicServerNoLock(user->GetGameServerId());
    if (game == 0) {
        return 0;
    }
    return game->GetConn();
}

void GateUserManager::NotifyWatcher(uint32 conn_id, const WatcherFunction& func)
{
    auto user = GetUser(conn_id);
    if (user == 0) {
        return;
    }
    user->ForEachWatcher(func);
}

UserVec GateUserManager::GetOnlineUsers(int32 start, int32 count)
{
    Lock l(mutex_);
    if ((int32)game_users_.size() <= start) {
        return UserVec();
    }

    boost::timer::cpu_times       elapsed_times(timer.elapsed());
    boost::timer::nanosecond_type elapsed(elapsed_times.wall);
    int32                         interval = (int32)(elapsed / 1000000000LL);
    if (interval >= SORT_USER_INTERVAL) {
        for (auto& u : game_users_) {
            user_vec_[u.second->GetUid()] = u.second;
        }
    }

    if ((int32)user_vec_.size() <= start) {
        return UserVec();
    }

    int32   rest = user_vec_.size() - start;
    int32   real_count = rest > count ? count : rest;
    UserVec vec;
    auto    it = user_vec_.begin();
    std::advance(it, start);
    auto it2 = it;
    std::advance(it2, real_count);
    while (it != it2) {
        vec.insert(*it);
        it++;
    }
    return vec;
}
