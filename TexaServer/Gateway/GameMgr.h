#ifndef _GAMEMGR_H
#define _GAMEMGR_H

#include <functional>
#include <string>
#include <unordered_map>


#include "../ServerLib/ServerCommon.h"

#define MAX_PLAYER_COUNT 9

#define IS_VALID_INSTANCE(id) ((id & (1 << 31)) == 0)

struct GameInstanceDesc {
    uint32 inst_id;
    uint32 logic_server_conn_id;

    std::string desc;

    // may bigger than max_player_count, because of observers
    int cur_player_count;
    int max_player_count;

    int64 min_enter_limit;
    int64 max_enter_limit;
    int64 default_carry;

    bool need_destroy;
};
static const GameInstanceDesc EmptyInstance = {-1, -1};

struct GameArenaDesc {
    std::string name;

    int32 player_limit;
    int64 match_fee;
    int64 pump;
    int64 award1;
    int64 award2;
    int64 award3;
};
static const GameArenaDesc EmptyArena = {"Unknown"};

using GameInstanceFunc = std::function<void(uint32, const GameInstanceDesc&)>;
class GameInstanceMgr {
public:
    GameInstanceMgr();

public:
    void AddInstance(int inst_count, const GameInstanceDesc& inst);

    GameInstanceDesc GetInstanceInfo(uint32 index);

    void EnumInstance(const GameInstanceFunc& func);

    std::string GetDesc(uint32 index);
    uint32      GetLogicServerByIndex(uint32 index);
    void        LogicServerDisconnect(uint32 gs_id);
    uint32      PlayerEnterGame(uint32 index, uint32 gs_id);
    void        PlayerLeaveGame(uint32 index);

    uint32 GetInstance(int64 player_gold);

private:
    std::vector<GameInstanceDesc> GetAllInstances();

private:
    std::unordered_map<uint32, GameInstanceDesc> instances_;
    uint32                                       index_;
};

class GameMgr {
public:
    void AddGame(const std::string& game, int inst_count, const GameInstanceDesc& inst);

    void EnumGame(const std::string& game, const GameInstanceFunc& func);

    GameInstanceDesc GetInstanceInfo(const std::string& game, uint32 index);

    uint32 GetLogicServerByIndex(const std::string& game, uint32 index);
    void   LogicServerDisconnect(const std::string& game, uint32 gs_id);
    uint32 PlayerEnterGame(uint32 conn_id, const std::string& game, uint32 index, uint32 gs_id);
    void   PlayerLeaveGame(uint32 conn_id, const std::string& game, uint32 index);

    uint32 GetProperInstance(int64 gold, const std::string& game);

private:
    // Game Name => Game Instances
    std::unordered_map<std::string, GameInstanceMgr> games_;
    std::mutex                                       mutex_;
};

inline GameMgr& GetGameMgr()
{
    static GameMgr mgr;
    return mgr;
}

#endif  // _GAMEMGR_H
