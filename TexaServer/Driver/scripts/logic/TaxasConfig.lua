RaiseMulti = {
	[1] = 1, [2] = 1, [3] = 1, [4] = 1,
	[5] = 1,
}

function CheckRaiseMulti(multi)
	return RaiseMulti[multi];
end

CardType = {
	1,		-- 红心
	2,		-- 方块
	3,		-- 黑心
	4		-- 梅花
}

-- 牌等级
CardLevel = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10
}

-- wanjia
--PlayerBetTimer = 10000
-- start game
--StartGameTimer = 10000

BetTimer = 15000;
DelayTimer = 2000;
GameTimer = {
	["StartGame"] = 10000,
	["CommonBet"] = BetTimer,
	["DealBet"] = BetTimer + DelayTimer,
	["OfterRound"] = BetTimer + DelayTimer
}

Redis_db = {
	["UserInfo"] = 0,
	["DailyDb"] = 10,
}

Liveness = {
	["Level1_Play"] = { ["Count"] = 10, ["Value"] = 1 },
	["Level1_Win"] = { ["Count"] = 5, ["Value"] = 2 },
	["Level2_Play"] = { ["Count"] = 10, ["Value"] = 1 },
	["Level2_Win"] = { ["Count"] = 5, ["Value"] = 2 },
	["UseItem"] = { ["Count"] = 10, ["Value"] = 1 },
	["Win10000"] = { ["Count"] = 5, ["Value"] = 2 },
	["Match_Play"] = { ["Count"] = 10, ["Value"] = 2 },
	["Match_Win"] = { ["Count"] = 5, ["Value"] = 4 },


	-- 每日最大值
	["ActDailyMax"] = 100,
}

TableExpCfg = {
	1, 2, 2, 3,
	4, 5, 6, 7,
	8, 9, 10, 10, 10
}

Exp_DailyMax = {
	["MaxExp"] = {
		2286, 9889, 38122,
		129597, 338211, 689793
	},

	["DailyMax"] = {
		500, 1000, 2000,
		3000, 4500, 6000
	}
}

Act_BoxConfig = {
	{ 20, 500 },
	{ 40, 1000 },
	{ 80, 2000 },
	{ 100, 5000 }
}

function isRoomLevel1(tTableInfo)
	if tTableInfo.Type == 1 or tTableInfo.Type == 2 or tTableInfo.Type == 3 or tTableInfo.Type == 4 then
		return 0;
	end
	return nil;
end

function isRoomLevel2(tTableInfo)
	if tTableInfo.Type == 5 or tTableInfo.Type == 6 or tTableInfo.Type == 7 or tTableInfo.Type == 8 then
		return 0;
	end
	return nil;
end

function isRoomLevel3(tTableInfo)
	if tTableInfo.Type == 9 or tTableInfo.Type == 10 or tTableInfo.Type == 11 or tTableInfo.Type == 12 or tTableInfo.Type == 13 then
		return 0;
	end
	return nil;
end

VipExpConfig = {
	{ 1, 10, 2, 20 },
	{ 2, 50, 3, 30 },
	{ 3, 100, 4, 40 },
	{ 4, 200, 5, 50 },
	{ 5, 500, 6, 60 },
	{ 6, 1000, 8, 80 },
	{ 7, 2000, 10, 100 },
	{ 8, 5000, 12, 120 },
	{ 9, 10000, 14, 140 },
	{ 10, 20000, 16, 160 },
	{ 11, 50000, 18, 180 },
	{ 12, 100000, 20, 200 }
}

function VipInfoByExp(exp)
	if exp <= 0 then
		return nil;
	end
	for i, v in pairs(VipExpConfig) do
		if exp <= v[2] then
			return v;
		end
	end

	return nil;
end
