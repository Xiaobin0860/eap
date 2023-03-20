#include "Storage.h"

#include "cppconn/exception.h"
#include "cppconn/statement.h"
#include "driver/mysql_connection.h"
#include "driver/mysql_driver.h"


#include "ClientGate.pb.h"
#include "DBGate.pb.h"


#include <sstream>
#include <thread>


class Stmt {
public:
    Stmt(sql::Connection* conn)
    {
        stmt_ = conn ? conn->createStatement() : 0;
    }
    ~Stmt()
    {
        if (stmt_ != 0) {
            stmt_->close();
            delete stmt_;
        }
    }

    operator bool()
    {
        return stmt_ != 0;
    }

    bool Execute(const std::string& sql)
    {
        if (stmt_ == 0) {
            return false;
        }

        try {
            return stmt_->execute(sql);
        }
        catch (sql::SQLException& e) {
            std::cout << "!!!!!!!!SQLException: " << sql << std::endl << "erro no: " << e.getErrorCode() << std::endl;
        }
        catch (...) {
        }
        return false;
    }
    sql::ResultSet* ExecuteQuery(const std::string& sql)
    {
        if (stmt_ == 0) {
            return 0;
        }

        try {
            return stmt_->executeQuery(sql);
        }
        catch (sql::SQLException& e) {
            std::cout << "!!!!!!!!SQLException: " << sql << std::endl << "erro no: " << e.getErrorCode() << std::endl;
        }
        catch (...) {
        }
        return 0;
    }
    int ExecuteUpdate(const std::string& sql)
    {
        if (stmt_ == 0) {
            return 0;
        }

        try {
            return stmt_->executeUpdate(sql);
        }
        catch (sql::SQLException& e) {
            std::cout << "!!!!!!!!SQLException: " << sql << std::endl << "erro no: " << e.getErrorCode() << std::endl;
        }
        catch (...) {
        }
        return 0;
    }

private:
    sql::Statement* stmt_;
};

static void FlushDB_Proc(Storage* storage)
{
    std::string sql;
    while (1) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));

        if (!storage->NextSql(sql))
            continue;

        if (!storage->FlushDB(sql)) {
            if (storage->SelectDB()) {
                storage->FlushDB(sql);
            }
        }
        sql.clear();
    }
}

Storage::Storage(const std::string& ip, const std::string& port, const std::string& user, const std::string& pass,
                 const std::string& db_name, int thread_count)
    : connection_(0)
    , thread_count_(thread_count)
    , connecting_(false)
{
    url_ = "tcp://" + ip + ':' + port;
    user_ = user;
    pass_ = pass;
    name_ = db_name;

    if (thread_count_ > 10)
        thread_count_ = 10;
    if (thread_count_ < 1)
        thread_count_ = 1;
}

bool Storage::SelectDB()
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt) {
        return false;
    }

    std::string use_it = "use " + name_ + ";";
    stmt.Execute(use_it);

    return true;
}

void Storage::StartFlushThr()
{
    for (int i = 0; i < thread_count_; i++) {
        std::thread thr(FlushDB_Proc, this);
        thr.detach();
    }
}

bool Storage::FlushDB(const std::string& sql)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return false;

    return stmt.ExecuteUpdate(sql) ? true : false;
    ;
}

void Storage::PushSql(const std::string& sql)
{
    std::lock_guard<std::mutex> l(exec_mutex_);
    exec_sql_.push(sql);
}

bool Storage::NextSql(std::string& sql)
{
    std::lock_guard<std::mutex> l(exec_mutex_);
    if (exec_sql_.empty())
        return false;

    sql = exec_sql_.front();
    exec_sql_.pop();
    return true;
}

bool Storage::Init()
{
    if (!Connect()) {
        return false;
    }

    if (!SelectDB()) {
        return false;
    }

    StartFlushThr();
    return true;
}

bool Storage::Connect()
{
    std::lock_guard<std::mutex> l(mutex_);
    if (connecting_)
        return false;

    if (connection_) {
        connection_->close();
    }

    connecting_ = true;
    sql::Driver* driver_ = sql::mysql::get_mysql_driver_instance();
    if (driver_ == 0) {
        connecting_ = false;
        return false;
    }

    sql::ConnectOptionsMap conn_prop;
    conn_prop["hostName"] = url_;
    conn_prop["userName"] = user_;
    conn_prop["password"] = pass_;
    conn_prop["OPT_CONNECT_TIMEOUT"] = 1000;
    conn_prop["OPT_RECONNECT"] = true;
    connection_ = driver_->connect(conn_prop);
    if (connection_ == 0) {
        driver_ = 0;
        connecting_ = false;
        return false;
    }

    connecting_ = false;
    return true;
}

bool Storage::OnRegist(const std::string& uuid, const std::string& name, const std::string& password,
                       const std::string& nick, const int gender, const int64 default_score)
{
    std::lock_guard<std::mutex> l(mutex_);
    std::ostringstream          ostr;
    ostr << "INSERT INTO user_info (id, account, pwd, nickname, gender, balance) VALUES(" << '\'' << uuid << '\'' << ','
         << '\'' << name << '\'' << ',' << '\'' << password << '\'' << ',' << '\'' << nick << '\'' << ',' << gender
         << ',' << default_score << ");";

    Stmt stmt(connection_);
    if (!stmt)
        return false;

    std::string use_it = "use " + name_ + ";";
    stmt.Execute(use_it);

    return stmt.ExecuteUpdate(ostr.str()) ? true : false;
}

void Storage::EnumUser(
    std::function<void(const std::string&, const std::string&, const ClientGate::BasicUserInfo&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM user_info;");
    if (!result)
        return;

    while (result->next()) {
        auto id = result->getString("id");
        auto account = result->getString("account");
        auto pwd = result->getString("pwd");
        auto nickname = result->getString("nickname");
        auto gender = result->getInt("gender");
        auto balance = result->getInt64("balance");
        auto lev = result->getUInt64("lev");
        auto exp = result->getUInt64("exp");
        auto vip_lev = result->getUInt64("vip_lev");
        auto activity = result->getUInt64("activity");

        ClientGate::BasicUserInfo info;
        info.set_user_id(id);
        info.set_avatar("");
        info.set_nick(nickname);
        info.set_gender((ClientGate::EnumGender)gender);
        info.set_user_score(balance);
        info.set_lev(lev);
        info.set_experience(exp);
        info.set_vip(vip_lev);
        info.set_activity(activity);

        fun(account, pwd, info);
    }
}

void Storage::EnumRoomConfig(std::function<void(uint64, const DBGate::RoomConfig&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM room_info;");
    if (!result)
        return;

    while (result->next()) {
        auto id = result->getUInt64("id");
        auto type_code = result->getInt("type_code");
        auto name = result->getString("name");
        auto chips = result->getInt64("chips");
        auto small_blind = result->getInt64("small_blind");
        auto big_blind = result->getInt64("big_blind");
        auto is_arena = result->getInt("is_arena");
        auto award = result->getString("award");
        auto is_show = result->getInt("is_show");
        auto min_chips = result->getInt64("min_chips");
        auto max_chips = result->getInt64("max_chips");
        auto entry_fee = result->getInt64("entry_fee");
        auto service_fee = result->getInt64("service_fee");
        auto amount = result->getInt("amount");
        auto item_price = result->getInt64("item_price");
        auto max_person_amount = result->getInt("max_person_amount");

        std::ostringstream desc;
        desc << max_person_amount << ',' << small_blind << ',' << big_blind << ',' << item_price << ',' << type_code;

        DBGate::RoomConfig config;
        config.set_count(amount);
        config.set_limit_min(min_chips);
        config.set_limit_max(max_chips);
        config.set_default_carry(chips);
        config.set_desc(desc.str());

        fun(id, config);
    }
}

void Storage::EnumArenaConfig(std::function<void(uint64, const DBGate::ArenaConfig&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM arena_info;");
    if (!result)
        return;

    while (result->next()) {
        auto id = result->getUInt64("id");
        auto name = result->getString("name");
        auto small_blind = result->getInt64("small_blind");
        auto big_blind = result->getInt64("big_blind");
        auto default_carry = result->getInt64("default_carry");
        auto player_limit = result->getInt("player_limit");
        auto match_fee = result->getInt("match_fee");
        auto pump = result->getInt64("pump");
        auto award = result->getString("award");
        auto active = result->getInt("active");
        auto item_price = result->getInt64("item_price");
        auto inc_time = result->getInt64("inc_time");
        auto inc_val = result->getString("inc_val");
        auto award_ex = result->getString("award_ex");

        std::ostringstream desc;
        desc << small_blind << ',' << big_blind << ',' << default_carry << ',' << item_price << ',' << inc_time << ','
             << inc_val;
        if (!award_ex->empty())
            desc << ',' << award_ex;

        DBGate::ArenaConfig config;
        config.set_name(name);
        config.set_player_limit(player_limit);
        config.set_match_fee(match_fee);
        config.set_pump(pump);
        config.set_award(award);
        config.set_desc(desc.str());

        fun(id, config);
    }
}

void Storage::EnumVipConfig(std::function<void(const DBGate::VipConfig&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM vip_info;");
    if (!result)
        return;

    while (result->next()) {
        auto no = result->getInt64("no");
        auto name = result->getString("name");
        auto exp = result->getInt64("exp");
        auto exp_bonus = result->getInt("exp_bonus");
        auto point_bonus = result->getInt("point_bonus");

        DBGate::VipConfig config;
        config.set_lev(no);
        config.set_name(name);
        config.set_exp(exp);
        config.set_exp_bonus(exp_bonus);
        config.set_point_bonus(point_bonus);

        fun(config);
    }
}

void Storage::EnumLevConfig(std::function<void(const DBGate::LevConfig&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM level_info;");
    if (!result)
        return;

    while (result->next()) {
        auto lev = result->getInt64("no");
        auto name = result->getString("name");
        auto exp = result->getInt64("exp");
        auto total_exp = result->getInt("exp_up");
        auto limit_exp = result->getInt("exp_day");

        DBGate::LevConfig config;
        config.set_lev(lev);
        config.set_name(name);
        config.set_exp(exp);
        config.set_total_exp(total_exp);
        config.set_limit_exp(limit_exp);

        fun(config);
    }
}

void Storage::EnumActivityConfig(std::function<void(const uint64 id, const DBGate::ActivityConfig&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM activity_info;");
    if (!result)
        return;

    while (result->next()) {
        auto id = result->getUInt64("id");
        auto target = result->getInt64("target");
        auto award = result->getString("award");

        DBGate::ActivityConfig config;
        config.set_target(target);
        config.set_award(award);

        fun(id, config);
    }
}

void Storage::EnumFriend(std::function<void(const std::string&, const std::string&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM user_friend;");
    if (!result)
        return;

    while (result->next()) {
        auto user_id = result->getString("user_id");
        auto friend_id = result->getString("friend_id");

        fun(user_id, friend_id);
    }
}

void Storage::EnumBaggage(std::function<void(const std::string&, const std::string&)> fun)
{
    std::lock_guard<std::mutex> l(mutex_);
    Stmt                        stmt(connection_);
    if (!stmt)
        return;

    auto result = stmt.ExecuteQuery("SELECT * FROM user_baggage;");
    if (!result)
        return;

    while (result->next()) {
        auto uuid = result->getString("uuid");
        auto desc = result->getString("desc");

        fun(uuid, desc);
    }
}

void Storage::SaveData(const ClientGate::BasicUserInfo& info)
{
    std::stringstream ost;
    ost << "UPDATE user_info SET "
        << "balance = " << info.user_score() << ' ' << "WHERE "
        << "id = " << '\'' << info.user_id() << '\'' << ';';

    PushSql(ost.str());
}

void Storage::SaveData(const std::string& uuid, const std::string& key, const std::string& val)
{
    std::stringstream ost;
    ost << "UPDATE user_info SET " << key << " = " << val << ' ' << "WHERE "
        << "id = " << '\'' << uuid << '\'' << ';';

    PushSql(ost.str());
}

void Storage::AddFriend(const std::string& uuid, const std::string& friend_id)
{
    auto flag = FriendShip(uuid, friend_id);
    if (flag == 0) {
        UpdateFriendShip(uuid, friend_id, 1);
    } else if (flag == -1) {
        AddFriendDB(uuid, friend_id);
    }
}

void Storage::DelFriend(const std::string& uuid, const std::string& friend_id)
{
    UpdateFriendShip(uuid, friend_id, 0);
}

int Storage::FriendShip(const std::string& uuid, const std::string& friend_id)
{
    std::lock_guard<std::mutex> l(mutex_);
    std::stringstream           ost;
    ost << "SELECT is_agree FROM user_friend"
        << " WHERE "
        << "user_id = " << '\'' << uuid << '\'' << " AND "
        << "friend_id = " << '\'' << friend_id << '\'' << ';';
    Stmt stmt(connection_);
    if (!stmt)
        return -1;

    auto result = stmt.ExecuteQuery(ost.str());
    if (!result)
        return -1;

    if (!result->next())
        return -1;

    return result->getInt("is_agree");
}

void Storage::AddFriendDB(const std::string& uuid, const std::string& friend_id)
{
    std::stringstream ost;
    ost << "INSERT INTO user_friend(user, friend_id, is_agree) "
        << "VALUES(" << '\'' << uuid << '\'' << ", " << '\'' << friend_id << '\'' << ", " << 1 << ");";

    PushSql(ost.str());
}

void Storage::UpdateFriendShip(const std::string& uuid, const std::string& friend_id, int flag)
{
    std::stringstream ost;
    ost << "UPDATE user_friend SET "
        << "is_agree"
        << " = " << flag << ' ' << "WHERE "
        << "user_id = " << '\'' << uuid << '\'' << " AND "
        << "friend_id = " << '\'' << friend_id << '\'' << ';';

    PushSql(ost.str());
}
