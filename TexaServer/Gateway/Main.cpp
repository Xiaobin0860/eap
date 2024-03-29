/*
 *                       _oo0oo_
 *                      o8888888o
 *                      88" . "88
 *                      (| -_- |)
 *                      0\  =  /0
 *                    ___/`---'\___
 *                  .' \\|     |// '.
 *                 / \\|||  :  |||// \
 *                / _||||| -:- |||||- \
 *               |   | \\\  -  /// |   |
 *               | \_|  ''\---/''  |_/ |
 *               \  .-\__  '-'  ___/-. /
 *             ___'. .'  /--.--\  `. .'___
 *          ."" '<  `.___\_<|>_/___.' >' "".
 *         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
 *         \  \ `_.   \_ __\ /__ _/   .-` /  /
 *     =====`-.____`.___ \_____/___.-`___.-'=====
 *                       `=---='
 *     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *               ���汣��         ����BUG
 */
#include "Gateway.h"

#include <string>
#include <vector>


#include "../ServerLib/CfgReader.h"

static std::vector<std::string> GetConfig()
{
    std::vector<std::string> result;

    CfgReader reader;
    reader.Read("./Gateway.cfg");
    std::string ip = reader["GatewayIP"];
    std::string port = reader["GatewayPort"];
    std::string pool_size = reader["IoServicePoolSize"];
    if (ip.empty() || port.empty()) {
        LOG("Please check Gateway.cfg!");
        return result;
    }

    if (pool_size.empty()) {
        pool_size = "1";
    }

    result.push_back(ip);
    result.push_back(port);
    result.push_back(pool_size);
    return result;
}

int main()
{
    Gateway gate;

    auto cfg = GetConfig();
    if (cfg.empty()) {
        return 0;
    }

    try {
        gate.Run(cfg[0], cfg[1], atoi(cfg[2].c_str()));
    }
    catch (std::exception& e) {
        LOG("exception: %s", e.what());
    }
}
