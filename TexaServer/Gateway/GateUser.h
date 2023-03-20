#ifndef _GATEUSER_H
#define _GATEUSER_H

#include <memory>
#include <mutex>
#include <unordered_map>
#include <unordered_set>


#include <boost/timer/timer.hpp>

#include "../ServerLib/ServerCommon.h"

#include "ClientGate.pb.h"

#define HEART_BEAT_INTERVAL 60

enum GateUserType {
    GU_TYPE_NA,             // ��ʼ��δ֪״̬
    GU_TYPE_GAME_SERVER,    // ��Ϸ������
    GU_TYPE_RECORD_SERVER,  // ���ݷ�����
    GU_TYPE_PLAYER,         // ��ͨ���
};
enum GateUserStatus {
    GU_STATUS_INIT,    // δ��½״̬
    GU_STATUS_IDLE,    // ��½�ɹ�
    GU_STATUS_GAMING,  // ��Ϸ��
};

using WatcherFunction = std::function<void(uint32)>;
class GateUser : public std::enable_shared_from_this<GateUser> {
public:
    GateUser(const ConnectionPtr& conn);

public:
    ConnectionPtr GetConn();
    void          Init();
    void          Destroy();
    void          ResetDeadLine();
    void          RemoveDeadLine();

    void AddWatcher(uint32 watcher);
    void RemoveWatcher(uint32 watcher);
    void ForEachWatcher(const WatcherFunction& func);

public:
    GETTER_SETTER(std::string, Sig);
    GETTER_SETTER(std::string, Uid);
    GETTER_SETTER(GateUserStatus, Status);
    GETTER_SETTER(ClientGate::BasicUserInfo, UserInfo);
    GETTER_SETTER(uint32, GameServerId);
    GETTER_SETTER(std::string, CurGame);
    GETTER_SETTER(uint32, RoomId);

private:
    void CheckDeadLine();

private:
    GateUserType  type_;
    ConnectionPtr conn_;

    boost::asio::deadline_timer deadline_;

    std::unordered_set<uint32> watcher_;
    std::unordered_set<uint32> subject_;
    std::mutex                 mutex_;
};
using GateUserPtr = std::shared_ptr<GateUser>;

inline ConnectionPtr GateUser::GetConn()
{
    return conn_;
}

//////////////////////////////////////////////////////////////////////////
// Gate User Manager
#define SORT_USER_INTERVAL 5  // refresh user list interval
typedef std::map<std::string, GateUserPtr> UserVec;
class GateUserManager {
public:
    void        AddUser(const ConnectionPtr& conn);
    bool        ChangeUserType(uint32 conn_id, GateUserType type, const std::string& sig = "",
                               const ClientGate::BasicUserInfo& info = ClientGate::BasicUserInfo());
    void        RemoveUser(uint32 conn_id);
    GateUserPtr GetAnyUser(uint32 conn_id);

    // Record Server
    GateUserPtr GetRecordServer(uint32 conn_id);
    GateUserPtr GetRecordServer();

    // Logic Server
    GateUserPtr   GetLogicServer(uint32 conn_id);
    uint32        GetRandomLogicServer();
    ConnectionPtr GetLogicServerFromUserConnId(uint32 conn_id);

    GateUserPtr GetUser(uint32 conn_id);
    std::string GetUserId(uint32 conn_id);
    GateUserPtr GetUserById(const std::string& user_id);

    void NotifyWatcher(uint32 conn_id, const WatcherFunction& func);

    UserVec GetOnlineUsers(int32 start, int32 count);

private:
    GateUserPtr GetRecordServerNoLock(uint32 conn_id);
    GateUserPtr GetLogicServerNoLock(uint32 conn_id);
    GateUserPtr GetUserNoLock(uint32 conn_id);

    // Client
    void SetUserInfo(uint32 conn_id, const ClientGate::BasicUserInfo& info);

private:
    std::unordered_map<uint32, GateUserPtr> unknown_users_, game_users_, logic_servers_, record_servers_;
    std::unordered_map<std::string, uint32> conn_id_map_;
    std::mutex                              mutex_;
    boost::timer::cpu_timer                 timer;
    UserVec                                 user_vec_;
};
inline GateUserManager& GetGateUserManager()
{
    static GateUserManager mgr;
    return mgr;
}

#endif  // _GATEUSER_H
