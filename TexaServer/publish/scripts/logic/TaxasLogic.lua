require("logic.TaxasTable")
require("logic.TaxasRedis")
require("logic.TaxasCard")
require("logic.TaxasConfig")

StartGameInfo = {
	["PlayerCards"] = { {} },	-- [uid]={crad. card}
}

-- 初始化桌子
function InitTable()
	math.randomseed(os.time());
end

-- 重置桌子
function ResetTable(tableInfo)
	tableInfo["Gameing"] = 1;
	tableInfo["SmallPlayer"] = 0;
	tableInfo["BigPlayer"] = 0;
	tableInfo["AllInPlayers"] = {};
	tableInfo["DwonCards"] = {};
	tableInfo["CurCards"] = 0;
	tableInfo["Steps"] = 0;
	tableInfo["CurMaxBet"] = 0;
	tableInfo["CurMaxRaise"] = 0;
	tableInfo["Pot"] = 0;
	tableInfo["CurPlayer"] = 0;
	tableInfo["Wins"] = {};
	tableInfo["SurplusPlayer"] = tableInfo["PlayerCount"];

	local tPlayers = tableInfo["Players"];
	for i, v in pairs(tPlayers) do
		v["OwnCard"] = {};
		v["SidePool"] = {};
		v["CurBet"] = 0;
		v["TotalBet"] = 0;
		v["Flod"] = 0;
		v["AllIn"] = 0;
		v["InGameing"] = 1;
	end
end

-- 检测桌子是否准备好
function CheckTableReady(tableInfo)
	if tableInfo["Gameing"] == 1 then
		return nil;
	end
	if tableInfo["PlayerCount"] < tableInfo["TableInfo"]["MinPlayerCount"] then
		return nil;
	end
	local tMinMoney = tableInfo["TableInfo"]["MinMoney"];
	for i, v in pairs(tableInfo["Players"]) do
		if v["Money"] < tMinMoney then
			return nil;
		end
	end
	
	return 0;
end

-- 检测桌子里的玩家是否符合条件
function CheckTablePlayers(tableInfo)
	local tMovePlayers = {};
	for i, v in pairs(tableInfo["Players"]) do
		if v["Money"] < tableInfo["TableInfo"]["MinMoney"] then
		table.insert(tMovePlayers, v);
	end
	if table.getn(tMovePlayers) <= 0 then
		return nil;
	end
	
	return tMovePlayers;
	end
end

-- 玩家进入桌子
function EnterTable(uid, tableInfo)
	-- 获取玩家信息
	local playerInfo = RedisGetPlayerInfo(uid);
	if playerInfo == nil then
		return 1;
	end

	-- 获取一个空位置
	local tEmptyIndex = FindEmptyIndex(tableInfo);
	if tEmptyIndex == nil then
		return 2;
	end
	-- 设置玩家位置
	tableInfo["Players"][tEmptyIndex] = playerInfo;
	playerInfo["Flod"] = 0;
	playerInfo["Index"] = tEmptyIndex;
	-- 增加一位玩家
	tableInfo["PlayerCount"] = tableInfo["PlayerCount"] + 1;

	return 0;
end

-- 玩家离开桌子
function LeaveTable(uid, tableInfo)
	-- 游戏非进行中
	if tableInfo["Gameing"] ~= 0 then
		return 1;
	end

	-- 玩家所在位置
	local tIndex = GetPlayerIndex(uid, tableInfo);
	if tIndex == nil then
		return 2;
	end

	-- 设置玩家离开
	table.remove(tableInfo["Players"], tIndex);
	tableInfo["PlayerCount"] = tableInfo["PlayerCount"] - 1;

	RemovePlayerBasicInfo(uid);
	return 0;
end

-- 比赛开始
function StartTable(tableInfo)
	-- 检测桌子是否准备好
	if CheckTableReady(tableInfo) ~= 0 then
		return 1;
	end
	-- 重置桌子
	ResetTable(tableInfo);
	-- 设置庄主位置
	NextButtonPlayer(tableInfo);
	-- 发牌
	GetCards(tableInfo); 
	-- 下大小盲注
	SmallAndBigRaise(tableInfo);
	-- 选择大盲注左侧玩家下注
	SetCurPlayer(0, tableInfo);

	return 0;
end

function SmallAndBigRaise(tableInfo)
	Raise(tableInfo["SmallPlayer"], tableInfo["TableInfo"]["SmallBlinds"], 0, tableInfo);
	Raise(tableInfo["BigPlayer"], tableInfo["TableInfo"]["BigBlinds"], 0, tableInfo);
end

-- 玩家放弃
function OnFlod(uid, tableInfo)
	local tIndex = StartPlay(uid, tableInfo);
	if tIndex == nil then
		return 1;
	end

	tableInfo["Players"][tIndex]["Flod"] = 1;
	tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
	
	local tRet = EndPlay(tIndex, tableInfo);
end

function OnCall(uid, tableInfo)
	local tIndex = StartPlay(uid, tableInfo);
	if tIndex == nil then
		return 1;
	end

	local tPlayer = tableInfo["Players"][tIndex];
	local tNeedBet = tableInfo["CurMaxBet"] - tPlayer["CurBet"];
	if tNeedBet ~= 0 then
		local tPlayerMoney = tPlayer["Money"];
		if tNeedBet < tPlayerMoney then	-- 跟注
			Call(tIndex, tNeedBet, tableInfo);
		else					-- AllIn
			AllIn(tableInfo);
			tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
		end
	end

	local tRet = EndPlay(tIndex, tableInfo);
	return tRet;
end

function OnRaise(uid, multi, tableInfo)
	local tIndex = StartPlay(uid, tableInfo);
	if tIndex == nil then
		return 1;
	end

	if CheckRaiseMulti(multi, tableInfo) == nil then
		return 2;
	end

	local tRaise = 0;
	local tBet = tableInfo["CurMaxBet"];
	local tCurMaxRaise = tableInfo["CurMaxRaise"];
	if tCurMaxRaise == 0 then
		tRaise = multi * tableInfo["TableInfo"]["BigBlinds"];
	else
		tRaise = multi * tCurMaxRaise;
	end
	tBet = tBet + tRaise;

	local tPlayerMoney = tableInfo["Players"][tIndex]["Money"];
	if tBet > tPlayerMoney then			-- 不够
		return 3;
	elseif tBet == tPlayerMoney then		-- AllIn
		AllIn(tIndex, tableInfo);
		tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
	else						-- 加注
		Raise(tIndex, tBet, tRaise, tableInfo);
	end

        local tRet = EndPlay(tIndex, tableInfo);
end

