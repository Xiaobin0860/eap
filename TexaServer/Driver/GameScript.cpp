#include "GameScript.h"

#include "../ServerLib/TcpConnection.h"
#include "../ServerLib/TcpServer.h"
#include "../ServerLib/logger.hpp"

#include "LuaBinder.h"
#include "LuaVM.h"

#define CHECK_VM_RUNNING()                                                                                             \
    if (!running_ || vm_ == 0) {                                                                                       \
        return;                                                                                                        \
    }

GameScript::GameScript(const std::string& script_name)
    : running_(false)
    , vm_(0)
    , script_(script_name)
{
}

void GameScript::Init()
{
    vm_ = new LuaVM;
    if (vm_ == 0) {
        LOG("Script env init fail");
        return;
    }

    LuaBinder binder;
    binder.Bind(vm_);

    if (!vm_->Load(script_)) {
        LOG("Load game main script fail");
        return;
    }

    running_ = true;
}

void GameScript::Run()
{
    CHECK_VM_RUNNING();

    vm_->Call("game_main");
}

TimerFunc GameScript::GetScriptFrameFunc()
{
    return std::bind(&GameScript::Run, shared_from_this());
}

void GameScript::Stop()
{
    running_ = false;
}

void GameScript::OnUserData(const uint8* buf, uint32 len)
{
    CHECK_VM_RUNNING();

    std::string pkt;
    pkt.append((const char*)buf, len);
    vm_->Call("OnUserData", pkt);
}
