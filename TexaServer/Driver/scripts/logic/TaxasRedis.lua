require("logic.TaxasTable")
require("logic.TaxasPlayer")
require("logic.TaxasConfig")
local redis = require("libs.redis")

Redis_client = nil

function redisIncrInt(key, field, value)
	Redis_client:select(Redis_db["DailyDb"]);
	return Redis_client:hincrby(key, field, value);
end

function RedisInit()
	Redis_client = redis.connect('192.168.0.249', 6379)
	return Redis_client:ping()
end


function RedisGetPlayerInfo(uid)
	Redis_client:select(Redis_db["UserInfo"]);
	local tKey = 'TexasPoker:USER:' .. uid .. ':desc'
	return Redis_client:hget('TexasPoker:USER', tKey)
end

function RedisGetDailyActivity(uid, condition, value)
	return redisIncrInt(uid, condition, value);
end

function RedisGetTotalActivity(uid, condition)
	Redis_client:select(Redis_db["DailyDb"]);
	return Redis_client:hget(uid, condition);
end

function RedisGetDailyExp(uid, exp)
	return redisIncrInt(uid, "DailyExp_Total", exp);
end

function RedisGetOpenBoxCount(uid, condition)
	return redisIncrInt(uid, condition, 1);
end
