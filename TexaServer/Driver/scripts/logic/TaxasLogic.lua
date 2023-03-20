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
function StartResetTable(tableInfo)
	tableInfo["Gameing"] = 1;
	tableInfo["Surplus"] = tableInfo["PlayerCount"];
	local tPlayers = tableInfo["Players"];
	for i, v in pairs(tPlayers) do
		tableInfo["StartMoney"][i] = v["Money"];
		v["InGameing"] = 1;
	end
end

function EndResetTable(tableInfo)
	tableInfo["SmallPlayer"] = 0;
	tableInfo["BigPlayer"] = 0;
	tableInfo["AllInPlayers"] = {};
	tableInfo["FlodPlayers"] = {};
	tableInfo["DownCards"] = {};
	tableInfo["CurCards"] = 0;
	tableInfo["PreStep"] = 0;
	tableInfo["Steps"] = 0;
	tableInfo["CurMaxBet"] = 0;
	tableInfo["CurMaxRaise"] = 0;
	tableInfo["Pot"] = 0;
	tableInfo["CurPlayer"] = 0;
	tableInfo["Wins"] = {};
	tableInfo["PlayCount"] = 0;	  -- 本轮下注次数
	tableInfo["EndCardInfo"] = {};	  -- 最后牌信息 [index] = {level, {cards}}
	tableInfo["AutoOperate"] = {}	  -- 系统操作次数
	tableInfo["WinPoolMoney"] = { ["main"] = {}, ["side"] = {} , ["return"] = {} }

	local tPlayers = tableInfo["Players"];
	for i, v in pairs(tPlayers) do
		v["OwnCard"] = {};
		v["SidePool"] = {};
		v["CurBet"] = 0;
		v["TotalBet"] = 0;
		v["Flod"] = 0;
		v["AllIn"] = 0;
		v["InGameing"] = 0;
	end
end

-- 检测桌子是否准备好
function CheckTableReady(tableInfo)
	if tableInfo["Gameing"] == 1 then
		print("errer, ingameing.")
		return nil;
	end
	if tableInfo["PlayerCount"] < tableInfo["TableInfo"]["MinPlayerCount"] then
		print("errer, Count :" .. tableInfo["PlayerCount"])
		return nil;
	end
	local tMinMoney = tableInfo["TableInfo"]["MinMoney"];
	for i, v in pairs(tableInfo["Players"]) do
		if v["Money"] < tMinMoney then
			print("errer, money. uid :" .. v["Uid"] .. ", curMoney :" .. v["Money"] .. ", minMoney :" .. tMinMoney)
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

function LookTable(uid, tableInfo, basicInfo)
	SetPlayerBasicInfo(uid, basicInfo);
	tableInfo["Lookers"][uid] = 1;
end

-- 玩家进入桌子
function EnterTable(uid, tableInfo, basicInfo, index)
	tableInfo["Lookers"][uid] = nil;
	-- 获取玩家信息
	SetPlayerBasicInfo(uid, basicInfo);
	if basicInfo == nil then
		return 1;
	end

	local playerInfo = createPlayer();
	playerInfo["Uid"] = uid;

	-- 最大金额的二分之一
	if basicInfo["user_score"] >= tableInfo["TableInfo"]["DefaultMoney"] then
		playerInfo["Money"] = tableInfo["TableInfo"]["DefaultMoney"];
	else
		playerInfo["Money"] = basicInfo["user_score"];
	end

	-- 获取一个空位置
	local tEmptyIndex = nil;
	if index ~= nil and index > 0 then
		if index > tableInfo["TableInfo"]["MaxPlayerCount"] then
			return 4;
		end
		if tableInfo["Players"][index] ~= nil then
			return 3;
		end
		tEmptyIndex = index;
	else
		tEmptyIndex = FindEmptyIndex(tableInfo);
	end
	if tEmptyIndex == nil then
		return 2;
	end
	-- 设置玩家位置
	tableInfo["Players"][tEmptyIndex] = playerInfo;
	playerInfo["Flod"] = 0;
	playerInfo["Index"] = tEmptyIndex;
	-- 增加一位玩家
	tableInfo["PlayerCount"] = tableInfo["PlayerCount"] + 1;
print("new player enter. index :" .. tEmptyIndex .. ", allCount :" .. tableInfo["PlayerCount"]);

	return 0;
end

function RemovePlayer(uid, tableInfo)
	-- 设置玩家离开
	RemovePlayerTable(uid, tableInfo);
	RemovePlayerBasicInfo(uid);
end

-- 玩家离开桌子
function LeaveTable(uid, tableInfo)
	-- 游戏非进行中
	--if tableInfo["Gameing"] ~= 0 then
	--	return 1;
	--end

	-- 玩家所在位置
	local tIndex, tPlayer = GetPlayerIndex(uid, tableInfo);
	if tIndex == nil or tPlayer == nil then
		return 2;
	end

	if tPlayer["InGameing"] == 1 then
		if tPlayer["Flod"] == 0 then
			SetOffPlayer(uid, tableInfo);
			return 1;
		else
			tableInfo["FlodPlayers"][uid] = tPlayer;
		end
	end
	--OnFlod(uid, tableInfo);

	RemovePlayer(uid, tableInfo);
	return 0;
end

-- 比赛开始
function StartTable(tableInfo)
	-- 检测桌子是否准备好
	if CheckTableReady(tableInfo) ~= 0 then
		return 1;
	end
	-- 重置桌子
	StartResetTable(tableInfo);
	-- 设置庄主位置
	NextButtonPlayer(tableInfo);
	-- 发牌
	GetCards(tableInfo); 
	-- 下大小盲注
	SmallAndBigRaise(tableInfo);
	-- 选择大盲注左侧玩家下注
	SetCurPlayer(0, tableInfo);
printTable(tableInfo)

	return 0;
end

function SmallAndBigRaise(tableInfo)
	Raise(tableInfo["SmallPlayer"], tableInfo["TableInfo"]["SmallBlinds"], 0, tableInfo);
	Raise(tableInfo["BigPlayer"], tableInfo["TableInfo"]["BigBlinds"], 0, tableInfo);
end

-- 玩家放弃
function OnFlod(uid, tableInfo)
	local tIndex, tPlayer = GetPlayerIndex(uid, tableInfo);
	if tPlayer["InGameing"] == 0 then
		return 1000000;
	end
	
	--local tIndex = StartPlay(uid, tableInfo);
	--if tIndex == nil then
	--	return 1;
	--end

	tPlayer["Flod"] = 1;
	tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
	
	local tRet = EndPlay(tIndex, tableInfo);
	return tRet;
end

function OnCall(uid, tableInfo)
	local tIndex = StartPlay(uid, tableInfo);
	if tIndex == nil then
		return 1;
	end
	
	local tPlayer = tableInfo["Players"][tIndex];
	local tNeedBet = tableInfo["CurMaxBet"] - tPlayer["CurBet"];
	local tPlayerMoney = tPlayer["Money"];
	if tNeedBet >= 0 then
		if tNeedBet < tPlayerMoney then	-- 跟注
			Call(tIndex, tNeedBet, tableInfo);
		else					-- AllIn
			tNeedBet = tPlayerMoney;
			AllIn(tIndex, tableInfo);
			--tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
		end
	end

	local tRet = EndPlay(tIndex, tableInfo);
	return tRet, tPlayerMoney - tNeedBet;
end

function OnRaise(uid, multi, tableInfo)
	local tIndex = StartPlay(uid, tableInfo);
	if tIndex == nil then
		return 1;
	end

	--if CheckRaiseMulti(multi, tableInfo) == nil then
	--	return 2;
	--end

	local tRaise = 0;
	local tBet = tableInfo["CurMaxBet"];
	local tCurMaxRaise = tableInfo["CurMaxRaise"];
	--if tCurMaxRaise == 0 then
	--	tRaise = multi * tableInfo["TableInfo"]["BigBlinds"];
	--else
	--	tRaise = multi * tCurMaxRaise;
	--end
	--tBet = tBet + tRaise;
	if multi < (tCurMaxRaise * 2) then
		print("error. Raise :" .. multi .. ", curRaiseBet :" .. tCurMaxRaise)
		return 2;
	else
		tBet = multi;
	end

	local tPlayerMoney = tableInfo["Players"][tIndex]["Money"];
	if tBet > tPlayerMoney then			-- 不够
		return 3;
	elseif tBet == tPlayerMoney then		-- AllIn
		AllIn(tIndex, tableInfo);
		--tableInfo["Surplus"] = tableInfo["Surplus"] - 1;
	else						-- 加注
		Raise(tIndex, tBet, multi, tableInfo);
	end

        local tRet = EndPlay(tIndex, tableInfo);
	return tRet, tPlayerMoney - tBet;
end

