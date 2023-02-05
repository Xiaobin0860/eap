PlayerBasicInfo = {
	["user_id"] = "",
	["nick"] = "",
	["avatar"] = "",
	["gender"] = 0,
	["user_score"] = 0,
	["experience"] = 0,
	["lev"] = 0,
	["vip"] = 0,
	["activity"] = 0,
}
function printBasicInfo(basic)
	print("################################Basic##########")
	
	print("user_id		:" .. basic.user_id)
	print("nick		:" .. basic.nick)
	print("avatar		:" .. basic.avatar)
	print("gender		:" .. basic.gender)
	print("user_score		:" .. basic.user_score)
	print("experience		:" .. basic.experience)
	print("lev		:" .. basic.lev)
	print("vip		:" .. basic.activity)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
end

PlayerTableInfo = {
	-- 持久化信息
	["Uid"] = 0,		  -- 玩家id
	["Money"] = 0,		  -- 拥有的金额
	
	-- 游戏中信息
	["Index"] = 0,		  -- 座位id
    	["OwnCard"] = {},         -- 手里的牌
    	["SidePool"] = {},        -- 边池
    	["CurBet"] = 0,           -- 当轮投注
	["TotalBet"] = 0,	  -- 总投注
    	["Flod"] = 0,		  -- 是否放弃
	["InGameing"] = 0,	  -- 游戏中
    	["AllIn"] = 0,            -- 全压钱数
}

TaxasTableInfo = {
	["Inited"] = 0,		  -- 初始化标示
	["Type"] = 0,		  -- 桌子类型
	["MinMoney"] = 0,	  -- 进入桌子最小金额
	["MaxMoney"] = 0,	  -- 进入桌子最大金额
	["DefaultMoney"] = 0,	  -- 进入默认金额
	["MinPlayerCount"] = 0,	  -- 最小玩家数
    	["MaxPlayerCount"] = 0,   -- 最大玩家数
	["BigBlinds"] = 0,        -- 大盲注
    	["SmallBlinds"] = 0,      -- 小盲注
	["ItemPrice"] = 1000,	  -- 道具价格
}

TaxasTable = {
	["TableId"] = 0,	  -- 桌子id
	["Gameing"] = 0,	  -- 游戏中标示
    	["TableInfo"] = nil,      -- 桌子信息

    	["Players"] = {},         -- 所有玩家
	["StartMoney"] = {},	  -- 游戏开始金额
	["PlayerCount"] = 0,	  -- 所有玩家个数

    	["ButtonPlayer"] = 0,  	  -- 当前庄家
	["SmallPlayer"] = 0,	  -- 小盲注玩家
	["BigPlayer"] = 0,	  -- 大盲注玩家
    	["AllInPlayers"] = {},    -- 全压的玩家
	["FlodPlayers"] = {},	  -- 弃牌的玩家
	["DownCards"] = {},	  -- 底牌
	["CurCards"] = 0,	  -- 当前揭牌
	["PreStep"] = 0,	  -- 上轮轮次
	["Steps"] = 0,	  	  -- 轮次
	["CurMaxBet"] = 0,	  -- 当前最大投注数
	["CurMaxRaise"] = 0,	  -- 当前最大加注数
    	["Pot"] = 0,              -- 底池
	["StartPlayer"] = 0,	  -- 第一个下注者
	["CurPlayer"] = 0,	  -- 当前下注玩家
	["Wins"] = {},		  -- 当局赢的玩家		[index] = {Card, Card}
	["EndCardInfo"] = {},	  -- 最后牌信息 [index] = {level, {cards}}
	["Surplus"] = 0,	  -- 剩下玩家个数
	["PlayCount"] = 0,	  -- 本轮下注次数
	["AutoOperate"] = {},	  -- 系统操作次数[index] = count
	["Lookers"] = {},	  -- 观看者
	["WinPoolMoney"] = { ["main"] = {}, ["side"] = {} , ["return"] = {} },
}

function printTable(tableInfo)
	print("###############################TableInfo#############")

	local tConfig = tableInfo["TableInfo"];
	print("Inited		: " .. tConfig["Inited"])
	print("MinMoney		: " .. tConfig["MinMoney"])
	print("MaxMoney		: " .. tConfig["MaxMoney"])
	print("MinPlayerCount	: " .. tConfig["MinPlayerCount"])
	print("MaxPlayerCount	: " .. tConfig["MaxPlayerCount"])
	print("BigBlinds	: " .. tConfig["BigBlinds"])
	print("SmallBlinds	: " .. tConfig["SmallBlinds"])
	print("")
	print("Gameing		: " .. tableInfo["Gameing"])
	print("PlayerCount	: " .. tableInfo["PlayerCount"])
	for i, v in pairs(tableInfo["Players"]) do
		print("PlayerInfo	: Uid - " .. v["Uid"] .. ", money - " .. v["Money"] .. ", CurBet - " .. v["CurBet"] .. ", TotalBet - " .. v["TotalBet"] .. ", flod - " .. v["Flod"] .. ", ingame - " .. v["InGameing"] .. ", Allin - " .. v["AllIn"]);
		for ii, vv in pairs(v["OwnCard"]) do
			print("OwnCard		: " .. vv)
		end
	end
	print("ButtonPlayer	: " .. tableInfo["ButtonPlayer"])
	print("SmallPlayer	: " .. tableInfo["SmallPlayer"])
	print("BigPlayer	: " .. tableInfo["BigPlayer"])
	for i, v in pairs(tableInfo["DownCards"]) do
		print("DownCards        : " .. v)
	end
	print("Steps		: " .. tableInfo["Steps"])
	print("CurMaxBet	: " .. tableInfo["CurMaxBet"])
	print("CurMaxRaise	: " .. tableInfo["CurMaxRaise"])
	print("Pot		: " .. tableInfo["Pot"])
	print("StartPlayer	: " .. tableInfo["StartPlayer"])
	print("CurPlayer	: " .. tableInfo["CurPlayer"])
	print("Surplus		: " .. tableInfo["Surplus"])
	for i, v in pairs(tableInfo["Wins"]) do
		print("Wins		: Index - " .. i .. ", Card - ".. v[1] .. ", " .. v[2] .. ", " .. v[3] .. ", " .. v[4] .. ", " .. v[5])
	end

	print("##################################################")
end

function parseTableConfig(config)
        local tTaxasConfig = {
                ["Inited"] = 0,           -- 初始化标示
		["Type"] = 0,		  -- 桌子类型
                ["MinMoney"] = 0,         -- 进入桌子最小金额
                ["MaxMoney"] = 0,         -- 进入桌子最大金额
		["DefaultMoney"] = 0,	  -- 进入默认金额
                ["MinPlayerCount"] = 0,   -- 最小玩家数 
                ["MaxPlayerCount"] = 0,   -- 最大玩家数 
                ["BigBlinds"] = 0,        -- 大盲注
                ["SmallBlinds"] = 0,      -- 小盲注
		["ItemPrice"] = 1000,	  -- 道具价格
        }

	local tA = Split(config, ",");

	tTaxasConfig["Inited"] = 1;
	tTaxasConfig["Type"] = tonumber(tA[8]);
	tTaxasConfig["MinMoney"] = tonumber(tA[1]);
	tTaxasConfig["MaxMoney"] = tonumber(tA[2]);
	tTaxasConfig["DefaultMoney"] = tonumber(tA[3]); 
	tTaxasConfig["MinPlayerCount"] = 2;
	tTaxasConfig["MaxPlayerCount"] = tonumber(tA[4]);
	tTaxasConfig["SmallBlinds"] = tonumber(tA[5]);
	tTaxasConfig["BigBlinds"] = tonumber(tA[6]);
	tTaxasConfig["ItemPrice"] = tonumber(tA[7]);

        return tTaxasConfig;
end

function createTable(config, id)
        local tTaxasTable = {
		["TableId"] = id,	  -- 桌子id
                ["Gameing"] = 0,          -- 游戏中标示
                ["TableInfo"] = config,   -- 桌子信息
        
                ["Players"] = {},         -- 所有玩家
		["StartMoney"] = {},	  -- 游戏开始金额
                ["PlayerCount"] = 0,      -- 所有玩家个数
        
                ["ButtonPlayer"] = 0,     -- 当前庄家
                ["SmallPlayer"] = 0,      -- 小盲注玩家
                ["BigPlayer"] = 0,        -- 大盲注玩家
                ["AllInPlayers"] = {},    -- 全压的玩家
		["FlodPlayers"] = {},	  -- 弃牌的玩家
                ["DownCards"] = {},       -- 底牌
		["CurCards"] = 0,	  -- 当前揭牌
		["PreStep"] = 0,	  -- 上轮轮次
                ["Steps"] = 0,            -- 轮次
                ["CurMaxBet"] = 0,        -- 当前最大投注数
                ["CurMaxRaise"] = 0,      -- 当前最大加注数
                ["Pot"] = 0,              -- 底池
		["StartPlayer"] = 0,	  -- 第一个下注者
                ["CurPlayer"] = 0,        -- 当前下注玩家
                ["Wins"] = {},            -- 当局赢的玩家               [index] = {Card, Card}
		["EndCardInfo"] = {},	  -- 最后牌信息 [index] = {level, {cards}}
		["Surplus"] = 0,
		["PlayCount"] = 0,	  -- 本轮下注次数
		["AutoOperate"] = {},	  -- 系统操作次数
		["Lookers"] = {},	  -- 观看者
		["WinPoolMoney"] = { ["main"] = {}, ["side"] = {} , ["return"] = {} },
        }
        return tTaxasTable;
end

function createPlayer()
	local tPlayerTableInfo = {
        	-- 持久化信息
        	["Uid"] = 0,		  -- 玩家id
        	["Money"] = 0,		  -- 拥有的金额
        	
        	-- 游戏中信息
		["Index"] = 0,		  -- 座位id
            	["OwnCard"] = {},         -- 手里的牌
            	["SidePool"] = {},        -- 边池
            	["CurBet"] = 0,           -- 当轮投注
        	["TotalBet"] = 0,	  -- 总投注
            	["Flod"] = 0,		  -- 是否放弃
		["InGameing"] = 0,	  -- 游戏中
            	["AllIn"] = 0,            -- 全压钱数
	}

	return tPlayerTableInfo;
end

-- 游戏中有效玩家
function validPlayer(player)
	if player ~= nil and player["Flod"] == 0 and player["InGameing"] == 1 then
		return 1;
	end

	return nil;
end

function RemovePlayerTable(uid, tableInfo)
	local tIndex, tPlayer = GetPlayerIndex(uid, tableInfo);
	-- 设置玩家离开
        tableInfo["Players"][tIndex] = nil;
        tableInfo["PlayerCount"] = tableInfo["PlayerCount"] - 1;
end

-- 桌子是否初始化
function checkTableInited(tableInfo)
	if tableInfo["TableInfo"] == nil then
		return nil;
	end
	if tableInfo["TableInfo"]["Inited"] == 0 then
print("mei lun xia yi ge :" .. tCurIndex)
		return nil;
	end
	return 1;
end

-- 获取某个位置上的下一位玩家
function getNextPlayer(index, tableInfo)
	print("DEBUG, index : " .. index)

	local tIndex = 0;
	local tMaxPlayerCount = tableInfo["TableInfo"]["MaxPlayerCount"];
	
	tIndex = index + 1;
	while tIndex <= tMaxPlayerCount do
		local tPlayer = tableInfo["Players"][tIndex];
if tPlayer == nil then
end
		if validPlayer(tPlayer) ~= nil then
			return tIndex;
		end
		tIndex = tIndex + 1;
	end

	tIndex = 1;
	while tIndex < index do
		local tPlayer = tableInfo["Players"][tIndex];
		if validPlayer(tPlayer) ~= nil then
			return tIndex;
		end
		tIndex = tIndex + 1;
	end
	
	print("DEBUG, none next player")
	return index;
end

-- 作为最后一个投注者
function isEndPlayer(curIndex, tableInfo)
	local tStartIndex = tableInfo["StartPlayer"];
	--if curIndex == tStartIndex then
	--	return 0;
	--end

	-- 获取下一个投注位置
	local tNextIndex = 0;
	local tMaxFind = 0;
	while tNextIndex == 0 do
		if tMaxFind > tableInfo["TableInfo"]["MaxPlayerCount"] then
			break;
		end
print("111111111111111111111")
		tNextIndex = getNextPlayer(curIndex, tableInfo);
		if tNextIndex == nil then
print("isEndPlayer nil 1")
			return 0;
		end
		if tableInfo["AllInPlayers"][tNextIndex] ~= nil then
			tNextIndex = 0;
		end
	end
	
	if tNextIndex == curIndex then
print("Next is cur")
		return 0;
	end
	if tNextIndex == tStartIndex then
print("Next is start")
		return 0;
	end
	if curIndex == tStartIndex then
		return nil;
	end

	local tIndex = 0;
	local tMaxPlayerCount = tableInfo["TableInfo"]["MaxPlayerCount"];
	if curIndex < tNextIndex then
		if tStartIndex > curIndex and tStartIndex < tNextIndex then
print("Next is A")
			return 0;
		else
print("isEndPlayer nil 2")
			return nil;
		end
	else
		if tStartIndex > tNextIndex and tStartIndex < curIndex then
print("isEndPlayer nil 3")
			return nil
		else
print("Next is B")
			return 0;
		end
	end
end

-- 下一个庄主
function NextButtonPlayer(tableInfo)
	if checkTableInited(tableInfo) == nil then
		return nil;
	end
	print("DEBUG,CurIndex:" .. tableInfo["ButtonPlayer"]);
	local tPlayerSize = table_maxn(tableInfo["Players"]);
	-- 设置第一个玩家为庄主
	if tableInfo["ButtonPlayer"] == 0 then
		local tAllPlayers = tableInfo["Players"];
		for i,v in pairs(tAllPlayers) do
			tableInfo["ButtonPlayer"] = i;
			break;
		end
		print("DEBUG,NextButton is " .. tableInfo["ButtonPlayer"]);
	else
		local tCurIndex = tableInfo["ButtonPlayer"];
		-- 重新设置庄主
		if tCurIndex >= tPlayerSize then
			for i,v in pairs(tableInfo["Players"]) do
                        	tableInfo["ButtonPlayer"] = i;
                            	break;
		        end
		-- 找到下一个玩家
		else
			while tCurIndex < tPlayerSize do
				tCurIndex = tCurIndex + 1;
				local tPlayer = tableInfo["Players"][tCurIndex]
				if tPlayer ~= nil then
					tableInfo["ButtonPlayer"] = tCurIndex;
					break;
				end 
			end
		end
		print("DEBUG,NextButton is " .. tableInfo["ButtonPlayer"]);
	end

	-- 设置小盲注
	SmallBlindsPlayer(tableInfo);
	-- 设置大盲注
	BigBlindsPlayer(tableInfo);
end

-- 找出一个空位置
function FindEmptyIndex(tableInfo)
        if checkTableInited(tableInfo) == nil then
                return nil;
        end
	local tMaxCount = tableInfo["TableInfo"]["MaxPlayerCount"];
	
	for i = 1, tMaxCount do
		if tableInfo["Players"][i] == nil then
			return i;
		end
	end
	return nil;
end

-- 小盲注位置
function SmallBlindsPlayer(tableInfo)
	if checkTableInited(tableInfo) == nil then
		return nil;
	end

	-- 直接获取小盲注位置
	local tSmall = tableInfo["SmallPlayer"];
	if tSmall ~= 0 then
		return tSmall;
	end

	-- 获取庄家左一为小盲注
	local tCurButton = tableInfo["ButtonPlayer"];
	local tSmallIndex = getNextPlayer(tCurButton, tableInfo);
	tableInfo["SmallPlayer"] = tSmallIndex;

	return tSmallIndex;
end

-- 大盲注位置
function BigBlindsPlayer(tableInfo)
	if checkTableInited(tableInfo) == nil then
		return nil;
	end

	-- 直接获取大盲注位置
	local tBig = tableInfo["BigPlayer"];
	if tBig ~= 0 then
		return tBig;
	end

	-- 获取小盲注
	local tSmallBlindsIndex = SmallBlindsPlayer(tableInfo);
	if tSmallBlindsIndex == nil then
		return nil;
	end

	-- 获取小盲注左一为大盲注
	local tBigIndex = getNextPlayer(tSmallBlindsIndex, tableInfo);
	tableInfo["BigPlayer"] = tBigIndex;

	return tBigIndex;
end

-- 设置当前下注玩家
function SetCurPlayer(t, tableInfo)
	if t == 0 then		-- 第一轮开始
		if tableInfo["CurPlayer"] == 0 then
			local tIndex = BigBlindsPlayer(tableInfo);
			tableInfo["CurPlayer"] = getNextPlayer(tIndex, tableInfo);
			tableInfo["StartPlayer"] = tableInfo["CurPlayer"];
		end
	elseif t == 1 then	-- 每轮的下一个玩家
		local tCurIndex = tableInfo["CurPlayer"];
		local tMaxFind = 0;
		while 1 do
			tMaxFind = tMaxFind + 1;
			if tMaxFind > tableInfo["TableInfo"]["MaxPlayerCount"] then
				break;
			end
			tCurIndex = getNextPlayer(tCurIndex, tableInfo);
			if tableInfo["AllInPlayers"][tCurIndex] == nil then
				tableInfo["CurPlayer"] = tCurIndex;
				break;
			end
		end
	else			-- 之后每论开始
		local tCurIndex = tableInfo["ButtonPlayer"];
		local tMaxFind = 0;
		while 1 do
			tMaxFind = tMaxFind + 1;
			if tMaxFind > tableInfo["TableInfo"]["MaxPlayerCount"] then
				break;
			end
			
			if table_size(tableInfo["AllInPlayers"]) == tableInfo["Surplus"] then
				break;
			end
			tCurIndex = getNextPlayer(tCurIndex, tableInfo);
			if tableInfo["AllInPlayers"][tCurIndex] == nil then
				tableInfo["CurPlayer"] = tCurIndex;
				tableInfo["StartPlayer"] = tableInfo["CurPlayer"];
				break;
			end
		end
	end
end

-- 查询玩家位置
function GetPlayerIndex(uid, tableInfo)
	local tPlayers = tableInfo["Players"];
	if tPlayers == nil then
		return nil;
	end

	for i, v in pairs(tPlayers) do
		if v["Uid"] == uid then
			return i, v;
		end
	end
	
	return nil, nil;
end
	
-- 检测本轮是否结束
function CheckEndCurRound(tableInfo)
	local tPlayers = tableInfo["Players"];
	local tCurMaxBet = tableInfo["CurMaxBet"];
	local tIsEndFlag = 0;
	for i, v in pairs(tPlayers) do
		if v["AllIn"] == 0 and v["Flod"] == 0 and v["InGameing"] == 1 then
			if tCurMaxBet ~= v["CurBet"] then
				tIsEndFlag = nil;
				break;
			end
		end
	end

	return tIsEndFlag;
end

-- 本轮结束
function EndCurRound(tableInfo)
	tableInfo["CurMaxBet"] = 0;
	tableInfo["CurMaxRaise"] = 0;
	SetCurPlayer(2, tableInfo);

	local tPlayers = tableInfo["Players"];
	for i, v in pairs(tPlayers) do
		v["TotalBet"] = v["TotalBet"] + v["CurBet"];
		v["CurBet"] = 0;
	end

	tableInfo["PreStep"] = tableInfo["Steps"];
	tableInfo["Steps"] = tableInfo["Steps"] + 1;
end

-- 玩家投注开始
function StartPlay(uid, tableInfo)
	-- 获取玩家位置
	local tIndex, _ = GetPlayerIndex(uid, tableInfo);
	if tIndex == nil then
		return nil;
	end

	-- 是否是当前下注者
	if tIndex ~= tableInfo["CurPlayer"] then
		return nil;
	end
	
	-- 返回位置
	return tIndex;
end

function endCurGame(tableInfo)
	CheckCards(tableInfo);
	Settle(tableInfo);
	tableInfo["Gameing"] = 0;
end

-- 玩家投注完毕
function EndPlay(index, tableInfo)
	tableInfo["PlayCount"] = tableInfo["PlayCount"] + 1;
	if tableInfo["Surplus"] <= 1 then
		EndCurRound(tableInfo);
		endCurGame(tableInfo);
		return -1;
	end
	-- 是否是最后一位下注者
	--if isEndPlayer(index, tableInfo) == 0 then
	local tAllInSize = table_size(tableInfo["AllInPlayers"]);
	local tSurplus = tableInfo["Surplus"] - tAllInSize;
	if tableInfo["AllInPlayers"][tableInfo["CurPlayer"]] ~= nil then
		tSurplus = tSurplus + 1;
	end

	if tableInfo["PlayCount"] >= tSurplus then
print("isEndPlayer, index :" .. index)
		local tFlag = CheckEndCurRound(tableInfo);
		if tFlag == 0 then
print("EndCurRound")
			EndCurRound(tableInfo);
			if (tableInfo["Surplus"] - tAllInSize) <= 1 or tableInfo["Steps"] > 3 then
				endCurGame(tableInfo);
				-- 这局结束
				return -1;
			else
				tableInfo["PlayCount"] = 0;
				-- 本轮结束
				return -2;
			end
		else
			SetCurPlayer(1, tableInfo);
		end
	else
		SetCurPlayer(1, tableInfo);
	end

	-- 下一个玩家
	return 0;
end

-- 跟注
function Call(index, money, tableInfo)
print("Call, index :" .. index .. ", money :" .. money .. ", tableid :" .. tableInfo["TableId"])
	local tPlayer = tableInfo["Players"][index];
	tPlayer["Money"] = tPlayer["Money"] - money;
	tPlayer["CurBet"] = tPlayer["CurBet"] + money;

	tableInfo["Pot"] = tableInfo["Pot"] + money;
	for i, v in pairs(tableInfo["AllInPlayers"]) do
		local tAllInPlayer = tableInfo["Players"][i];
		local tCurSidePoolPlayer = tAllInPlayer["SidePool"][index];
		if tCurSidePoolPlayer == nil then
			tCurSidePoolPlayer = money;
		else
			tCurSidePoolPlayer = tCurSidePoolPlayer + money;
		end
	end
end

-- 加注
function Raise(index, money, multiMoney, tableInfo)
print("Raise, index :" .. index .. ", money :" .. money .. ", addMoney :" .. multiMoney .. ", tableid :" .. tableInfo["TableId"])
	Call(index, money, tableInfo);

	tableInfo["CurMaxBet"] = tableInfo["Players"][index]["CurBet"];
	tableInfo["CurMaxRaise"] = multiMoney;
end

-- 全压
function AllIn(index, tableInfo)
	local tPlayers = tableInfo["Players"];
	local tPlayer = tPlayers[index];
print("Allin, index :" .. index .. ", money :" .. tPlayer["Money"] .. ", tableid :" .. tableInfo["TableId"])
	tPlayer["AllIn"] = tPlayer["Money"];
	tPlayer["CurBet"] = tPlayer["CurBet"] + tPlayer["Money"];
	tPlayer["Money"] = 0;
	
	--tPlayer["SidePool"][index] = 0;
	local tPreIndex = tableInfo["StartPlayer"];
	local tMaxFind = 0;
	while tPreIndex ~= nil and tPreIndex ~= index do
		if tMaxFind > tableInfo["TableInfo"]["MaxPlayerCount"] then
			break;
		end
		tPlayer["SidePool"][tPreIndex] = tPlayers[tPreIndex]["CurBet"];
		tPreIndex = getNextPlayer(tPreIndex, tableInfo);
	end
	tableInfo["Pot"] = tableInfo["Pot"] + tPlayer["AllIn"];
	tableInfo["AllInPlayers"][index] = 1;

	if tableInfo["Players"][index]["CurBet"] > tableInfo["CurMaxBet"] then
		tableInfo["CurMaxBet"] = tableInfo["Players"][index]["CurBet"];
	end
end

-- 结算
--function settle()
--	local twins = tableinfo["wins"];
--	local tplayers = tableinfo["players"];
--	local tallinplayerwin = {};
--	local tnotallinplayerwin = {};
--	local twincount = 0;
--	for i, v in pairs(twins) do
--		twincount = twincount + 1;
--
--		local tcurplayer = tplayers[i];
--		local tsidepool = tcurplayer["SidePool"];
--		local twinmoney = tableinfo["Pot"];
--
--		if tableinfo["allinplayers"][i] == nil then
--			tnotallinplayerwin[i] = tWinMoney;
--		else
--			for si, sv in pairs(tSidePool) do
--				twinmoney = tWinMoney - (sv - tCurPlayer["CurBet"]);
--			end
--			tallinplayerwin[i] = tWinMoney;
--		end
--	end
--	
--	table.sort(tallinplayerwin);
--	local ttotalwinmoney = 0;
--	local tpremoney = 0;
--	local tprewinmoney = 0;
--	for i, v in pairs(tallinplayerwin) do
--		local tcurmoney = v - tpreMoney;
--		tpremoney = v;
--
--		tprewinmoney = tprewinmoney + tCurMoney / tWinCount;
--		twins[i] = tprewinmoney;
--		ttotalwinmoney = ttotalwinMoney + tPreWinMoney;
--		twincount = twincount - 1;
--	end
--
--	tPrewinmoney = (tableinfo["pot"] - tTotalWinMoney) / tWinCount;
--	for i, v in pairs(tnotallinplayerWin) do
--		ttotalwinmoney = ttotalwinMoney + tPreWinMoney;
--		twins[i] = tprewinmoney;
--	end
--end

--function calcSidePool(allinIndex, allinMoney, index, player, isFirst, curSidePoolMoney, oneSidePool, mainPoolSize, mainPool)
--	if player["InGameing"] == 1 then
--	        local tMoney = player["TotalBet"] + player["CurBet"];            
--
--		local tMainPoolInfo = nil;
--		for i, v in pairs(mainPool) do
--			if v["index"] == index then
--				tMainPoolInfo = v;
--				break;
--			end
--		end
--		if tMainPoolInfo == nil then
--			tMainPoolInfo = { ["index"] = index, ["money"] = 0 };
--			table.insert(mainPool, tMainPoolInfo);
--		end
--		if tMainPoolInfo["money"] > allinMoney or tMoney > allinMoney then
--			tMainPoolInfo["money"] = allinMoney;
--		else
--			tMainPoolInfo["money"] = tMoney;
--		end
--
--	        if allinIndex ~= index then
--	                if tMoney > allinMoney then      
--	                        local tAddMoney = tMoney - allinMoney;    
--	                        curSidePoolMoney = curSidePoolMoney + tAddMoney;
--	                        local tPoolInfo = { ["index"] = index, ["money"] = tAddMoney } 
--	                        table.insert(oneSidePool["pools"], tPoolInfo);
--	                end
--	        end             
--	end
--
--	return curSidePoolMoney, mainPoolSize, ;
--end

function RoundSidePool(tableInfo)
	local tSortAllinMoney = {}
	local tNotFlodMoney = {}
	for index, player in pairs(tableInfo["Players"]) do
		if player["InGameing"] == 1 and player["Flod"] == 0 then
			local tCurMoney = player["TotalBet"] + player["CurBet"];
			tNotFlodMoney[tCurMoney] = 1;
		end
	end
	for i, v in pairs(tNotFlodMoney) do
		table.insert(tSortAllinMoney, i);
	end
	table.sort(tSortAllinMoney);

	local tMainPoolAllMoney = 0; -- money
	local tMainPool = { ["pools"] = {} } -- info
	local tSidePoolSomeAllMoney = {} -- index-money
	local tSidePool = {} -- index-info

	local tIsFirst = 0;
	local tPreAllinMoney = 0;
	for i, v in pairs(tSortAllinMoney) do
		local tSPool = { ["index"] = i, ["pools"] = {} }
		local tSMoney = { ["index"] = i, ["money"] = 0 }

		local tAllinMoney = v - tPreAllinMoney;
		--local tPoolAllMoney = 0;
		for index, player in pairs(tableInfo["Players"]) do
			if player["InGameing"] == 1 then
				local tPool = { ["index"] = index, ["money"] = 0 }
				local tCurPlayerMoney = player["TotalBet"] + player["CurBet"] - tPreAllinMoney;
				if tCurPlayerMoney > 0 then
					if tCurPlayerMoney < tAllinMoney then
						tPool["money"] = tCurPlayerMoney;
					else
						tPool["money"] = tAllinMoney;
					end

					if tIsFirst == 0 then
						table.insert(tMainPool["pools"], tPool);
						tMainPoolAllMoney = tMainPoolAllMoney + tPool["money"];
					else
						table.insert(tSPool["pools"], tPool);
						tSMoney["money"] = tSMoney["money"] + tPool["money"];
					end
				end
			end
		end
		for index, player in pairs(tableInfo["FlodPlayers"]) do
                        if player["InGameing"] == 1 then
                                local tPool = { ["index"] = index, ["money"] = 0 }
                                local tCurPlayerMoney = player["TotalBet"] + player["CurBet"] - tPreAllinMoney;
				if tCurPlayerMoney > 0 then
                                	if tCurPlayerMoney < tAllinMoney then
                                	        tPool["money"] = tCurPlayerMoney;
                                	else
                                	        tPool["money"] = tAllinMoney;
                                	end

                                	if tIsFirst == 0 then
                                	        table.insert(tMainPool["pools"], tPool);
						tMainPoolAllMoney = tMainPoolAllMoney + tPool["money"];
                                	else
                                	        table.insert(tSPool["pools"], tPool);
						tSMoney["money"] = tSMoney["money"] + tPool["money"];
                                	end
				end
                        end
                end
		if tIsFirst == 1 then
			table.insert(tSidePool, tSPool);
			table.insert(tSidePoolSomeAllMoney, tSMoney);
		end

		tIsFirst = 1;
		tPreAllinMoney = tAllinMoney + tPreAllinMoney;
	end

        return tMainPool, tMainPoolAllMoney, tSidePool, tSidePoolSomeAllMoney;
end

function Settle(tableInfo)
	local tWinPoolMoney = { ["main"] = { ["pools"] = {} }, ["side"] = {} , ["return"] = { ["pools"] = {} } }

	local tMainPool, tMainPoolAllMoney, tSidePool, tSidePoolSomeAllMoney = RoundSidePool(tableInfo);
	local tWins = tableInfo["Wins"];
	local tWinCount = table_size(tWins);
	local tPlayers = tableInfo["Players"];

	local tMaxWinMoney = 0;
	for i, v in pairs(tWins) do
		local tPlayer = tPlayers[i];
		if tMaxWinMoney < tPlayer["TotalBet"] then
			tMaxWinMoney = tPlayer["TotalBet"];
		end

		-- 主池中赢的钱
		local tMoney = tMainPoolAllMoney / tWinCount;
		local tMainMoney = { ["index"] = i, ["money"] = tMoney };
		table.insert(tWinPoolMoney["main"]["pools"], tMainMoney);
		tPlayer["Money"] = tPlayer["Money"] + tMoney;
	end

	-- 边池中赢的钱
	for is, vs in pairs(tSidePool) do
		local tCurSideWinCount = 0
		local tCurSideWins = {};
		for ip, vp in pairs(vs["pools"]) do
			for iw, vw in pairs(tWins) do
				if iw == vp["index"] then
					tCurSideWinCount = tCurSideWinCount + 1;
					table.insert(tCurSideWins, iw);
				end
			end
		end

		local tCurSideWinInfo = { ["index"] = vs["index"], ["pools"] = {} }
		for iw, vw in pairs(tCurSideWins) do
			local tPlayer = tPlayers[vw];
			local tMoney = tSidePoolSomeAllMoney[is]["money"] / tCurSideWinCount;
			local tSideMoney = { ["index"] = vw, ["money"] = tMoney };
			table.insert(tCurSideWinInfo["pools"], tSideMoney); 
			tPlayer["Money"] = tPlayer["Money"] + tMoney;
		end
		table.insert(tWinPoolMoney["side"], tCurSideWinInfo);
	end

	for i, v in pairs(tPlayers) do
		if v["TotalBet"] > tMaxWinMoney then
			local tMoney = v["TotalBet"] - tMaxWinMoney;
			local tReturnMoney = { ["index"] = i, ["money"] = tMoney };
			table.insert(tWinPoolMoney["return"]["pools"], tReturnMoney);
			v["Money"] = v["Money"] + tReturnMoney["money"];
		end
	end

	tableInfo["WinPoolMoney"] = tWinPoolMoney;
end

-- 
--function Settle(tableinfo)
--	local tWins = tableinfo["Wins"];
--	local tWinCount = 0;
--	local tWinMaxBet = 0;
--
--	local tPlayers = tableinfo["Players"];
--	local tPot = tableinfo["Pot"];
--	local tWinMoneys = {};
--	for iW, vW in pairs(tWins) do
--		tWinCount = tWinCount + 1;
--
--		local tPlayer = tPlayers[iW];
--print("WinPlayer, uid :" .. tPlayer["Uid"] .. ", Money :" .. tPlayer["Money"])
--		local tPlayerBet = tPlayer["TotalBet"];
--		if tPlayerBet > tWinMaxBet then
--			tWinMaxBet = tPlayerBet;
--		end
--
--		for ip, vp in pairs(tPlayers) do
--			if vp["InGameing"] == 1 then
--				if tWinMoneys[iW] == nil then
--					tWinMoneys[iW] = 0;
--				end
--				local tOtherBet = vp["TotalBet"];
--				if tPlayerBet <= tOtherBet then
--print("~~~~~~~~~~~~~~~" .. tPlayerBet .. "!!" .. tOtherBet)
--					tWinMoneys[iW] = tWinMoneys[iW] + tPlayerBet;
--				else
--print("~~~~~~~~~~~~~~~@@@@" .. tPlayerBet .. "!!" .. tOtherBet)
--					tWinMoneys[iW] = tWinMoneys[iW] + tOtherBet;
--				end
--			end
--		end
--		for iF, vF in pairs(tableinfo["FlodPlayers"]) do
--			if tWinMoneys[iW] == nil then
--                                tWinMoneys[iW] = 0;
--                        end
--                        local tOtherBet = vF["TotalBet"];
--                        if tPlayerBet <= tOtherBet then
--                                tWinMoneys[iW] = tWinMoneys[iW] + tPlayerBet;                   
--                        else
--                                tWinMoneys[iW] = tWinMoneys[iW] + tOtherBet;
--                        end	
--		end
--	end
--
--	for iw, vw in pairs(tWinMoneys) do
--		local tWin = vw / tWinCount;
--		tWinMoneys[iw] = tWin;
--		local tPlayer = tPlayers[iw];
--print("WinMoney1, uid :" .. tPlayer["Uid"] .. ", Money :" .. tPlayer["Money"] .. ", win :" .. vw .. ", ss :" .. tWin)
--		tPlayer["Money"] = tPlayer["Money"] + tWin;
--print("WinMoney1, uid :" .. tPlayer["Uid"] .. ", Money :" .. tPlayer["Money"])
--	end
--	for ip, vp in pairs(tPlayers) do
--		if vp["InGameing"] == 1 and vp["Flod"] == 0 and tWinMoneys[ip] == nil then
--			if vp["TotalBet"] > tWinMaxBet then
--print("WinPlayer2, uid :" .. vp["Uid"] .. ", Money :" .. vp["Money"] .. ", MaxBet :" .. tWinMaxBet)
--				vp["Money"] = vp["Money"] + vp["TotalBet"] - tWinMaxBet;
--print("WinPlayer2, uid :" .. vp["Uid"] .. ", Money :" .. vp["Money"])
--			end
--		end
--	end
--end
