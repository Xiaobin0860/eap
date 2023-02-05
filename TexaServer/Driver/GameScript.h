#ifndef _GAME_SCRIPT_H
#define _GAME_SCRIPT_H

#include <functional>
#include <memory>
#include <mutex>

#include "../ServerLib/ServerCommon.h"

class LuaVM;
class GameScript : public std::enable_shared_from_this<GameScript> {
public:
    GameScript(const std::string& script_name);

public:
    void Init();
    void Stop();

    // script callbacks
    void OnUserData(const uint8* buf, uint32 len);

    TimerFunc GetScriptFrameFunc();

    LuaVM* GetVM();

private:
    // called by Driver with an interval 5ms
    void Run();

private:
    LuaVM*      vm_;
    bool        running_;
    std::string script_;
};
using GameScriptPtr = std::shared_ptr<GameScript>;

inline LuaVM* GameScript::GetVM()
{
    return vm_;
}

#endif  // _GAME_SCRIPT_H
