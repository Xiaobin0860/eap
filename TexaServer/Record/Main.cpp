#include <stdio.h>
#include <stdlib.h>

#include "../ServerLib/CfgReader.h"
#include "../ServerLib/ServerCommon.h"
#include "../ServerLib/logger.hpp"

#include "PacketDataCache.h"
#include "RecordClient.h"
#include "RedisClient.h"
#include "Storage.h"


#include <functional>

int main()
{
    try {
        CfgReader reader;
        reader.Read("./Record.cfg");

        std::string game_name = reader["GameName"];
        std::string default_score_str = reader["DefaultScore"];
        auto        default_score = atoll(default_score_str.c_str());

        std::string gate_ip = reader["GatewayIP"];
        std::string gate_port = reader["GatewayPort"];

        std::string db_ip = reader["DBIP"];
        std::string db_port = reader["DBPort"];
        std::string db_user = reader["DBUser"];
        std::string db_password = reader["DBPassword"];
        std::string db_name = reader["DBName"];
        int         db_thread = atoi(reader["DBThread"].c_str());

        std::string redis_ip = reader["RedisIP"];
        std::string redis_port = reader["RedisPort"];
        std::string redis_user = reader["RedisUser"];
        std::string redis_password = reader["RedisPassword"];

        Storage storage(db_ip, db_port, db_user, db_password, db_name, db_thread);
        if (!storage.Init())
            return 0;

        IoService    ios;
        RecordClient record(storage, game_name, default_score, gate_ip, gate_port);
        RedisClient  redis(std::bind(&RecordClient::RedisHandler, &record, std::placeholders::_1), redis_ip, redis_port,
                           redis_user, redis_password);

        logger_.reset(new services::logger(ios, "Record"));
        record.Init(ios);
        redis.Init(ios);

        record.SetRedis(&redis);
        record.InitRedis();

        ios.run();
    }
    catch (...) {
        printf("Exception\n");
    }

    return 0;
}
