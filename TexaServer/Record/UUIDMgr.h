#ifndef _UUIDMGR_H
#define _UUIDMGR_H

#include <map>
#include <mutex>
#include <string>


class UUIDMgr {
public:
    void Add(const std::string& name, const std::string& uuid)
    {
        std::lock_guard<std::mutex> l(mutex_);
        name_uuid_[name] = uuid;
    }
    std::string Get(const std::string& name)
    {
        std::lock_guard<std::mutex> l(mutex_);
        auto                        iter = name_uuid_.find(name);
        if (iter == name_uuid_.end())
            return "";

        return iter->second;
    }
    void Del(const std::string& name)
    {
        std::lock_guard<std::mutex> l(mutex_);
        auto                        iter = name_uuid_.find(name);
        if (iter == name_uuid_.end())
            return;
        name_uuid_.erase(iter);
    }

private:
    std::mutex                         mutex_;
    std::map<std::string, std::string> name_uuid_;
};  // UUIDMgr

inline UUIDMgr& GetUUIDMgr()
{
    static UUIDMgr mgr;
    return mgr;
}

#endif  // _UUIDMGR_H
