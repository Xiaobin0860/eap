#include "GateUser.h"

#include "../ServerLib/TcpConnection.h"

GateUser::GateUser(const ConnectionPtr& conn)
    : type_(GU_TYPE_NA)
    , Status_(GU_STATUS_INIT)
    , conn_(conn)
    , deadline_(conn->GetIoService())
    , GameServerId_(-1)
    , RoomId_(-1)
{
}

void GateUser::Init()
{
    ResetDeadLine();
}

void GateUser::Destroy()
{
    RemoveDeadLine();
}

void GateUser::ResetDeadLine()
{
    deadline_.expires_from_now(boost::posix_time::seconds(HEART_BEAT_INTERVAL));
    deadline_.async_wait(std::bind(&GateUser::CheckDeadLine, shared_from_this()));
}

void GateUser::RemoveDeadLine()
{
    deadline_.cancel();
}

void GateUser::CheckDeadLine()
{
    if (deadline_.expires_at() <= boost::asio::deadline_timer::traits_type::now()) {
        conn_->Shutdown();
    }
}

void GateUser::AddWatcher(uint32 watcher)
{
    Lock l(mutex_);
    watcher_.insert(watcher);
}

void GateUser::RemoveWatcher(uint32 watcher)
{
    Lock l(mutex_);
    watcher_.erase(watcher);
}

void GateUser::ForEachWatcher(const WatcherFunction& func)
{
    Lock l(mutex_);
    for (auto& conn_id : watcher_) {
        func(conn_id);
    }
}
