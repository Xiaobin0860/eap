#include "Driver.h"

#include <string>
#include <vector>


#include "../ServerLib/CfgReader.h"

static std::vector<std::string> GetConfig()
{
    std::vector<std::string> result;

    CfgReader reader;
    reader.Read("./Driver.cfg");
    std::string ip = reader["GatewayIP"];
    std::string port = reader["GatewayPort"];
    std::string name = reader["GameName"];
    std::string script_entry = reader["ScriptEntry"];
    if (ip.empty() || port.empty() || name.empty() || script_entry.empty()) {
        LOG("Please check Driver.cfg!");
        return result;
    }

    result.push_back(ip);
    result.push_back(port);
    result.push_back(name);
    result.push_back(script_entry);
    return result;
}

int main()
{
    auto cfg = GetConfig();
    if (cfg.empty()) {
        return 0;
    }

    driver = new Driver(cfg[0], cfg[1], cfg[2], cfg[3]);

    try {
        driver->Run();
    }
    catch (std::exception& e) {
        LOG("exception: %s", e.what());
    }
}
