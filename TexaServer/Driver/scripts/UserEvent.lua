require("logic.TaxasTableManager")
require("logic.TaxasConfig")
require("logic.TaxasPlayer")
require("logic.TaxasRedis")
require("logic.TaxasLevel")

local protobuf = require "protobuf"

function RegProtoBuf(file_name)
    local protocolenum = io.open(file_name, "rb")
    local buffer = protocolenum:read "*a"
    protocolenum:close()

    protobuf.register(buffer)
end

local proto_files = {
    "./scripts/pb/Protocol.pb",
    "./scripts/pb/Packet.pb",
    "./scripts/pb/Gateway.pb",
    "./scripts/pb/Common.pb",
    "./scripts/pb/ClientGate.pb",
};
for _, v in pairs(proto_files) do
    RegProtoBuf(v)
end

RedisInit()

AllPlayersConn = {
	
}
AllPlayersId = {

}

function setPlayerConnect(conn, uid)
        if not uid then
                print('setPlayerConnect not valid uid');
        end
        AllPlayersConn[uid] = conn;
	AllPlayersId[conn] = uid;
end

function clearPlayerConnect(conn)
	local tUid = AllPlayersId[conn];
	if tUid ~= nil then
		AllPlayersId[conn] = nil;
		AllPlayersConn[tUid] = nil;
	end
end

function getPlayerConnect(uid)
	return AllPlayersConn[uid];
end

function getPlayerId(conn)
	return AllPlayersId[conn];
end

function sendPkg(pkg)
print("SendPkt #####################" .. pkg["command"])
	local tPkg = protobuf.encode("PB.ForwardingPacket", pkg);
	local driver = GetDriver()
	driver:Send(tPkg);
end

AllTimer = {

}

function startTimerByPlayer(uid, func, time)
	local tTable = GetTableByPlayer(uid);
	if AllTimer[tTable["TableId"]] ~= nil then
		return nil;
	end
	
	local driver = GetDriver()
	AllTimer[tTable["TableId"]] = driver:StartTimer(tTable["TableId"], func, time);
end

function stopTimerByPlayer(uid)
	local tTable = GetTableByPlayer(uid);
	local tTime = AllTimer[tTable["TableId"]];
	if tTime == nil then
		return nil;
	end
	
	local driver = GetDriver()
        driver:StopTimer(tTime);
	AllTimer[tTable["TableId"]] = nil;
end

function startTimerByTable(tableId, func, time)
	if AllTimer[tableId] ~= nil then
		return nil;
	end

	local driver = GetDriver()
	AllTimer[tableId] = driver:StartTimer(tableId, func, time);
end

function stopTimerByTable(tableId)
	local tTime = AllTimer[tableId];
	if tTime ~= nil then
		local driver = GetDriver()
        	driver:StopTimer(tTime);
		AllTimer[tableId] = nil;
	end
end

function getTimerTime(tableId)
	local tTimerTime = AllTimer[tableId];
	if tTimerTime == nil then
		return nil;
	end
	local driver = GetDriver();
	return driver:GetRestTime(tTimerTime);
end

function setPlayerConn(uid, conns, tableInfo, opt)
	local tFirst = nil;
	for i, v in pairs(tableInfo["Players"]) do
        	if uid == nil or v["Uid"] ~= uid then
			local tConnect = getPlayerConnect(v["Uid"]);
			if tConnect ~= nil then
        			table.insert(conns, tConnect);
				tFirst = 1;
			end
		end
	end
	for i, v in pairs(tableInfo["Lookers"]) do
		local tConnect = getPlayerConnect(i);
		if tConnect ~= nil then
			table.insert(conns, tConnect);
			tFirst = 1;
                end
	end
	return tFirst;
end

function isEndGame(tableInfo, timerType)
	local tRet = 0;
	if tableInfo["Gameing"] == 0 or (tableInfo["Surplus"] ~= nil and tableInfo["Surplus"] <= 1) then
		tRet = 1;
	else
		if tableInfo["CurCards"] < tableInfo["Steps"] then
			tRet = 2;
			tableInfo["CurCards"] = tableInfo["CurCards"] + 1;
			timerType = "OfterRound";
		end
	end

	return tRet;
end

function endGame(tableInfo, timerType, endType)
	if endType == 1 then
		--if tableInfo["Surplus"] ~= nil and tableInfo["Surplus"] <= 1 then
        		OnSettle(tableInfo);
		--end
        else
		if endType == 2 then
			OnSendDownCards(tableInfo);
		end
        	startTimerByPlayer(tableInfo["Players"][tableInfo["CurPlayer"]]["Uid"], "OnPlayerTimerOut", GameTimer[timerType]);
	end
end

function sidePool(pool, tableInfo)
	local tMaxPool = 0;
	for i, v in pairs(tableInfo["AllInPlayers"]) do
		local tCurPlayer = tableInfo["Players"][i];
		local tCurMoney = tCurPlayer["TotalBet"] + tCurPlayer["CurBet"];
		local tSidePool = { ["index"] = i, ["money"] = 0 }
		for ii, vv in pairs(tableInfo["Players"]) do
			if i ~= ii then
				local tMoney = vv["TotalBet"] + vv["CurBet"];
				if tMoney > tCurMoney then
					tSidePool["money"] = tSidePool["money"] + tMoney - tCurMoney;
				end
			end
		end
		if tMaxPool < tSidePool["money"] then
			tMaxPool = tSidePool["money"];
		end
		table.insert(pool, tSidePool);
	end
print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~sidePool :" .. tableInfo["Pot"] .. "~~~" .. tMaxPool)
	return tableInfo["Pot"] - tMaxPool;
end

function startGameTimer(tableInfo)
	if tableInfo["Gameing"] == 0 and tableInfo["PlayerCount"] >= tableInfo["TableInfo"]["MinPlayerCount"] then
                startTimerByTable(tableInfo["TableId"], "OnStartGame", GameTimer["StartGame"]);
        end
end

function sendSaveData(uid, name, value)
	print("save data :" .. uid .. ", str :" .. name .. ", value :" .. value)
	local tValue = nil;
	if type(value) == 'number' then
		tValue = tostring(value);
	else
		tValue = value;
	end
	local tSaveBody = {
		["name"] = name,
		["str"] = tValue,
	}
	local tSaveHead = {
		["command"] = "SAVE_DATA",
		["user_conn_id"] = getPlayerConnect(uid),
		["user_id"] = uid,
		["others_conn_id"] = {},
	}
        tSaveHead.serialized = protobuf.encode("GatewayServer.SaveData", tSaveBody);

	sendPkg(tSaveHead);
end

function setTotalActivity(uid, condition)
	if RedisGetDailyActivity(uid, "ActDailyMax", Liveness[condition]["Value"]) < Liveness["ActDailyMax"] then
		RedisGetDailyActivity(uid, "ActTotal", Liveness[condition]["Value"]);
	end
end

function playerSettle(uid, index, player, tableInfo)
	local tBasicInfo = GetPlayerBasicInfo(uid);
	local tIsWin = tableInfo["Wins"][index];
	-- 金额
	local tMoney = player["Money"] - tableInfo["StartMoney"][index];
	if tMoney > 0 or tMoney < 0 then
		tBasicInfo["user_score"] = tBasicInfo["user_score"] + tMoney;
		sendSaveData(uid, "balance", tMoney);
	end

	-- 经验
	local tExp = 0;
	if tIsWin == nil then
		tExp = LoseGameExp(uid, tBasicInfo);
	else
		tExp = WinGameExp(uid, tBasicInfo, tableInfo);
	end

	if tExp ~= nil then
		-- Vip增加额外经验
		local tVipLevel = VipInfoByExp(tBasicInfo["vip"]);
		if tVipLevel ~= nil and tVipLevel > 0 then
			tExp = math.floor(tExp + tExp * VipExpConfig[tVipLevel][4] / 100);
		end

		if tExp > 0 then
			sendSaveData(uid, "exp", tExp);
		end
	end

	-- 活跃
	local tTableInfo = tableInfo["TableInfo"];
	local tPlayCondition = nil;
	local tWinCondition = nil;
	local tTotalWinCondition = nil;
	if isRoomLevel1(tTableInfo) ~= nil then
		tPlayCondition = "Level1_Play";
		if tIsWin ~= nil then
			if tMoney >= 10000 then
				tTotalWinCondition = "Win10000";
			end
			tWinCondition = "Level1_Win";
		end
	elseif isRoomLevel2(tTableInfo) ~= nil then
		tPlayCondition = "Level2_Play";
		if tIsWin ~= nil then
			if tMoney >= 10000 then
				tTotalWinCondition = "Win10000";
			end
			tWinCondition = "Level2_Win";
		end
	end
	
	if tPlayCondition ~= nil then
		if RedisGetDailyActivity(uid, tPlayCondition, 1) == Liveness[tPlayCondition]["Count"] then
			setTotalActivity(uid, tPlayCondition)
		end
	end
	if tWinCondition ~= nil then
		if RedisGetDailyActivity(uid, tWinCondition, 1) == Liveness[tWinCondition]["Count"] then
			setTotalActivity(uid, tWinCondition)
		end
	end
	if tTotalWinCondition ~= nil then
		if RedisGetDailyActivity(uid, tTotalWinCondition, 1) == Liveness[tTotalWinCondition]["Count"] then
			setTotalActivity(uid, tTotalWinCondition)
		end
	end
end

function buyItem(uid, price)
	local tBasicInfo = GetPlayerBasicInfo(uid);
	tBasicInfo["user_score"] = tBasicInfo["user_score"] - price;
	sendSaveData(uid, "balance", 0 - price);
	if RedisGetDailyActivity(uid, "UseItem", 1) == Liveness["UseItem"]["Count"] then
		setTotalActivity(uid, "UseItem")
	end
end

function sendPlayerLeave(uid)
	local tConn = getPlayerConnect(uid);
        local tLeaveHead = {
                ["command"] = "CLIENT_LEAVE_GAME",
                ["user_conn_id"] = tConn,
                ["user_id"] = uid,
                ["others_conn_id"] = {},
        }
        sendPkg(tLeaveHead);
end

function sendOtherPlayerLeave(uid, tableInfo)
	local tOtherBody = {["user_id"] = uid};
	local tOtherHead = {
	                ["command"] = "CLIENT_OTHER_LEAVE_GAME",
	                ["user_conn_id"] = 0,
	                ["user_id"] = 0,
	                ["others_conn_id"] = {},
	}
	tOtherHead.serialized = protobuf.encode("ClientGate.OtherLeaveGame", tOtherBody)
	
	local tFirst = setPlayerConn(uid, tOtherHead["others_conn_id"], tableInfo, nil);
	if tFirst ~= nil then
		sendPkg(tOtherHead);
	end
end

function getTableAllInfo(tableInfo, uid)
	local tUserInfos = {};

	local tTable = tableInfo;
	local tPlayers = tTable["Players"];
	for i, v in pairs(tPlayers) do
                local tBaseInfo = GetPlayerBasicInfo(v["Uid"]);
                local tTableInfo = v;
                local tPlayerInfo = { ["user_base"] = tBaseInfo, ["user_table"] = tTableInfo};
                table.insert(tUserInfos, tPlayerInfo);
        end
        -- 桌子信息
        local tTableInfo = {
                ["Gameing"] = tTable["Gameing"], ["ButtonPlayer"] = tTable["ButtonPlayer"], ["SmallPlayer"] = tTable["SmallPlayer"],
                ["BigPlayer"] = tTable["BigPlayer"], ["DownCards"] = {}, ["CurMaxBet"] = tTable["CurMaxBet"],
                ["Pot"] = tTable["Pot"], ["CurPlayer"] = tTable["CurPlayer"], ["side_pool"] = {}, ["main_pool"] = 0,
                ["timer"] = 0, ["small_money"] = tTable["TableInfo"]["SmallBlinds"], ["big_money"] = tTable["TableInfo"]["BigBlinds"]
        }
        local CardCount = 0;
        if tTable["Steps"] > 0 then
                CardCount = 2 + tTable["Steps"];
        end
        if CardCount > 0 then
                for i = 1, CardCount do
                        table.insert(tTableInfo["DownCards"], tTable["DownCards"][i]);
                end
        end
        tTableInfo["main_pool"] = sidePool(tTableInfo["side_pool"], tTable);

        local tTimerTime = getTimerTime(tTable["TableId"]);
        if tTimerTime ~= nil then
                tTableInfo["timer"] = tTimerTime;
        end

        return tUserInfos, tTableInfo;
end

function addMoney(uid, playerInfo, tableInfo)
	local tBasicInfo = GetPlayerBasicInfo(uid);
	local tAddMoney = 0;
	if tBasicInfo["user_score"] >= tableInfo["TableInfo"]["DefaultMoney"] then
		tAddMoney = tableInfo["TableInfo"]["DefaultMoney"];
	else
		tAddMoney = tBasicInfo["user_score"];
	end

	playerInfo["Money"] = playerInfo["Money"] + tAddMoney;
	return tAddMoney;
end

function setPlayerFlod(uid, conn)
	local tFlodHead = {
                        ["command"] = "CLIENT_FLOD",
                        ["user_conn_id"] = conn,
                        ["user_id"] = uid,
                        ["others_conn_id"] = {},
        }
	onFlod(tFlodHead, 1);
end

function setPlayerCall(uid, conn)
	local tCallHead = {
                        ["command"] = "CLIENT_CALL",
                        ["user_conn_id"] = conn,
                        ["user_id"] = uid,
                        ["others_conn_id"] = {},
	}
	onCall(tCallHead, 1);
end

function setPlayerLeave(uid, conn)
	local tLeaveHead = {
                        ["command"] = "CLIENT_OTHER_LEAVE_GAME",
                        ["user_conn_id"] = conn,
                        ["user_id"] = uid,
                        ["others_conn_id"] = {},
	}
	onLeave(tLeaveHead, 1);
end

function setPlayerEnter(uid, conn, game_name, room_id, desc, seat_id)
	local tEnterHead = {
			["command"] = "CLIENT_OTHER_ENTER_GAME",
                        ["user_conn_id"] = conn,
                        ["user_id"] = uid,
                        ["others_conn_id"] = {},
	}
	local tEnterBody = {
			["game_name"] = game_name,
			["room_id"] = room_id,
			["desc"] = desc,
			["seat_id"] = seat_id,
	}
	tEnterHead["serialized"] = protobuf.encode("ClientGate.EnterGameRequest", tEnterBody);

	onEnter(tEnterHead);
end

Test_user = "1";
aa = 0;

function onLook(t)
	local tLookReq = protobuf.decode("ClientGate.LookTable", t["serialized"]);
	local tUid = t["user_id"];
	local tConn = t["user_conn_id"];
	local tGameName = tLookReq["game_name"];
	local tTableId = tLookReq["room_id"];
	local tTableDesc = tLookReq["desc"];
print("DEBUG, onLook :" .. tUid .. ", roomid :" .. tTableId)

	local tLookRes = {
		["result"] = "enumResultFail",
		["table_info"] = {},
		["user_info"] = {}
	}
	local tInTableFlag = 0;

	local tIndex = nil;
	local tTable = GetTableByTableId(tTableId);
	local tPlayer = nil;
	if tTable ~= nil then
		tIndex, tPlayer = GetPlayerIndex(tUid, tTable);
		if tPlayer ~= nil and (tPlayer["InGameing"] == 0 or tPlayer["Flod"] == 1) then
			tInTableFlag = 1;
			setPlayerLeave(tUid, tConn);
			tIndex = nil;
		end
	end

	if tIndex == nil then
		if tTable == nil then
			setPlayerEnter(tUid, tConn, tGameName, tTableId, tTableDesc, 0);
			return;
		end
		if tTable ~= nil and tInTableFlag == 0 then
			local tFindIndex = FindEmptyIndex(tTable);
			if tFindIndex ~= nil then
				setPlayerEnter(tUid, tConn, tGameName, tTableId, tTableDesc, tFindIndex);
				return;
			end
		end

		local tDesc = RedisGetPlayerInfo(tUid);
		if tDesc ~= nil then
			local tBasicInfo = protobuf.decode("ClientGate.BasicUserInfo", tDesc);
			if tBasicInfo ~= nil then
        			setPlayerConnect(tConn, tUid);
				PlayerLookTable(tUid, tTableId, tTableDesc, tBasicInfo);
				tLookRes["result"] = "enumResultSucc";
				tTable = GetTableByTableId(tTableId);                  
				if tTable ~= nil and tPlayer == nil then
					local tUserInfos, tTableCurInfo = getTableAllInfo(tTable, tUid);
					tLookRes["user_info"] = tUserInfos;
					tLookRes["table_info"] = tTableCurInfo;
				end
			end
		end
	end

        t["command"] = "CLIENT_LOOK_TABLE_RESPONSE";
	t["others_conn_id"] = {}
        t["serialized"] = protobuf.encode("ClientGate.LookTableResponse", tLookRes);
	-- 发响应包
	sendPkg(t)
end

function onEnter(t)
print("DEBUG, onEnter #" .. t["user_id"] .. "#")
	local tEnterReq = protobuf.decode("ClientGate.EnterGameRequest", t["serialized"]);
        local tEnterRes = {
                ["result"] = "enumResultSucc",
		["table_info"] = {},
                ["user_info"] = {}
	}
	if t["user_id"] == "" then
		return nil;
	end

        print('test ' .. t["user_conn_id"] .. ' ' .. t["user_id"] .. ' ' .. tEnterReq["room_id"] .. ' ' .. tEnterReq["desc"] .. ' ' .. tEnterReq["seat_id"])

        setPlayerConnect(t["user_conn_id"], t["user_id"]);
	local tRet = 0;
	-- 进入桌子
	local tPlayerTable = GetOffPlayer(t["user_id"]);
	if tPlayerTable == nil then
		local tTable = GetTableByTableId(tEnterReq["room_id"]);
		local tIndex = nil;
		if tTable ~= nil then
			tIndex, _ = GetPlayerIndex(t["user_id"], tTable);
		end                  
		if tIndex == nil then
			print("Enter new.")
                        local tDesc = RedisGetPlayerInfo(t["user_id"]);
                        if tDesc ~= nil then
                                local tBasicInfo = protobuf.decode("ClientGate.BasicUserInfo", tDesc);
                                if tBasicInfo ~= nil then
printBasicInfo(tBasicInfo)
                                        tRet = PlayerEnterTable(t["user_id"], tEnterReq["room_id"], tEnterReq["desc"], tBasicInfo, tEnterReq["seat_id"]);
                                else
                                        print("basicinfo nil")
                                        tRet = 100000;
                                end
                        else
                                print("desc nil")
                                tRet = 100000;
                        end
		end
	else
		RemoveOffPlayer(t["user_id"])
	end

        if tRet ~= 0 then
		print("Enter fail.")
                tEnterRes["result"] = "enumResultFail";
        else
		print("Enter succeed.")
		-- 返回桌子玩家信息
                local tTable = GetTableByTableId(tEnterReq["room_id"]);                  
                if tTable ~= nil then                           
			tTable["Lookers"][t["user_id"]] = nil;
			-- 其他玩家加入
			local tOtherBody = {
				["result"] = "enumResultSucc",
				["user_info"] = nil;
			}
                        local tOtherHead = {
				["command"] = "CLIENT_OTHER_ENTER_GAME",
				["user_conn_id"] = 0,
				["user_id"] = 0,
				["others_conn_id"] = {}
			};

			local tFirst = setPlayerConn(t["user_id"], tOtherHead["others_conn_id"], tTable, nil);
			local tPlayers = tTable["Players"];
			-- 所有玩家信息
printTable(tTable)
                        for i, v in pairs(tPlayers) do
				local tBaseInfo = GetPlayerBasicInfo(v["Uid"]);
				if v["Uid"] == t["user_id"] then
					tOtherBody["user_info"] = { ["user_base"] = tBaseInfo, ["user_table"] = v };
				end
                        end

			local tUserInfos, tTableCurInfo = getTableAllInfo(tTable, t["user_id"]);
			tEnterRes["user_info"] = tUserInfos;
			tEnterRes["table_info"] = tTableCurInfo;
			if tFirst ~= nil then
                        	tOtherHead.serialized = protobuf.encode("ClientGate.OtherEnterGameResponse", tOtherBody)
				-- 发other响应包
				sendPkg(tOtherHead)
			end

			startGameTimer(tTable);
                end
        end

	-- 玩家加入
        t["command"] = "CLIENT_ENTER_GAME_RESPONSE";
	t["others_conn_id"] = {}
        t["serialized"] = protobuf.encode("ClientGate.EnterGameResponse", tEnterRes);
	-- 发响应包
	sendPkg(t)
end

function onLeave(t)
print("DEBUG, onLeave." .. t["user_id"])
	if t["user_id"] == '' then
		t["user_id"] = getPlayerId(t["user_conn_id"]);
	end
        local tTable = GetTableByPlayer(t["user_id"]);                  
	if tTable == nil then
		return nil;
	end

	local tLooker = tTable["Lookers"][t["user_id"]];
	if tLooker ~= nil then
		tTable["Lookers"][t["user_id"]] = nil;
	else
		if PlayerLeaveOutTable(t["user_id"]) == 0 then
        	        -- 其他玩家
        	        sendOtherPlayerLeave(t["user_id"], tTable);
        	        sendPlayerLeave(t["user_id"]);
        	        if tTable["PlayerCount"] < tTable["TableInfo"]["MinPlayerCount"] then
        	                stopTimerByTable(tTable["TableId"]);
        	        end
        	end
	end

	clearPlayerConnect(t["user_conn_id"]);
end

function onFlod(t, flag)
print("DEBUG, onFlod." .. t["user_id"])
	local tTable = GetTableByPlayer(t["user_id"]);
	local tFlodRes = {
		["result"] = "enumResultSucc",
		["next_user_id"] = ""
	}
	if tTable ~= nil then
        	t["command"] = "CLIENT_FOLD_RESPONSE";
        	t["others_conn_id"] = {}
		local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
		if OnFlod(t["user_id"], tTable) > 0 then
			tFlodRes["result"] = "enumResultFail";
        		t["serialized"] = protobuf.encode("ClientGate.UserFlodResponse", tFlodRes)
        		sendPkg(t);
		else
printTable(tTable)
			stopTimerByPlayer(t["user_id"]);
			local tTimerType = "CommonBet";
			local tEndRet = isEndGame(tTable, tTimerType);

			if flag == 0 then
				tTable["AutoOperate"][tCurIndex] = 0;
			else
				if tTable["AutoOperate"][tCurIndex] == nil then
					tTable["AutoOperate"][tCurIndex] = 1;
				else
					tTable["AutoOperate"][tCurIndex] = tTable["AutoOperate"][tCurIndex] + 1;
				end
			end
			local tPlayers = tTable["Players"];
			local tNextPlayer = "";
			if tTable["Gameing"] == 1 and tEndRet == 0 then
				tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
			end
			local tCurTotalBet = tPlayers[tTable["CurPlayer"]]["CurBet"];
			local tMaxRaise = tTable["CurMaxBet"];

			-- 组合响应包
			tFlodRes["next_user_id"] = tNextPlayer;

			-- 其他玩家
			local tOtherBody = {["user_id"] = t["user_id"], ["next_user_id"] = tNextPlayer,
					["cur_round_total_bet"] = tCurTotalBet, ["cur_round_max_raise"] = tMaxRaise };
			local tOtherHead = {
					["command"] = "CLIENT_OTHER_FLOD",
					["user_conn_id"] = 0,
                                        ["user_id"] = 0,
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserFlod", tOtherBody)
			}
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserFlod", tOtherBody)
			local tFirst = setPlayerConn(t["user_id"], tOtherHead["others_conn_id"], tTable, nil);
			if tFirst ~= nil then
				sendPkg(tOtherHead)
			end
			local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
			playerSettle(t["user_id"], tCurIndex, tCurPlayer, tTable);

			tFlodRes["cur_round_total_bet"] = tCurTotalBet;
			tFlodRes["cur_round_max_raise"] = tMaxRaise;
        		t["serialized"] = protobuf.encode("ClientGate.UserFlodResponse", tFlodRes)
        		sendPkg(t);
        		endGame(tTable, tTimerType, tEndRet);
		end
	end
end

function onCall(t, flag)
print("DEBUG, onCall." .. t["user_id"])
	local tTable = GetTableByPlayer(t["user_id"]);
	local tCallRes = {
                ["result"] = "enumResultSucc",
		["money"] = 0,
                ["next_user_id"] = "",
		["side_pool"] = {},
		["main_pool"] = 0
        }
        if tTable ~= nil then
        	t["command"] = "CLIENT_CALL_RESPONSE";
        	t["others_conn_id"] = {}
		local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
		local tRet, tCallBet = OnCall(t["user_id"], tTable);
                if tRet > 0 then
			print("onCall, errno :" .. tRet)
                        tCallRes["result"] = "enumResultFail";
        		t["serialized"] = protobuf.encode("ClientGate.UserCallResponse", tCallRes)
        		sendPkg(t);
                else
printTable(tTable)
			stopTimerByPlayer(t["user_id"]);
			local tTimerType = "CommonBet";
			local tEndRet = isEndGame(tTable, tTimerType);

			if flag == 0 then
				tTable["AutoOperate"][tCurIndex] = 0;
			else
				if tTable["AutoOperate"][tCurIndex] == nil then
					tTable["AutoOperate"][tCurIndex] = 1;
				else
					tTable["AutoOperate"][tCurIndex] = tTable["AutoOperate"][tCurIndex] + 1;
				end
			end
                        local tPlayers = tTable["Players"];
			local tNextPlayer = "";
			if tTable["Gameing"] == 1 and tEndRet == 0 then
                        	tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
			end
			local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
			local tCurMoney = tCallBet;
			local tCurTotalBet = tPlayers[tTable["CurPlayer"]]["CurBet"];
			local tMaxRaise = tTable["CurMaxBet"];
                        -- 组合响应包
			tCallRes["money"] = tCurMoney;
                        tCallRes["next_user_id"] = tNextPlayer;

                        -- 其他玩家     
                        local tOtherBody = {["user_id"] = t["user_id"], ["money"] = tCurMoney, ["next_user_id"] = tNextPlayer, ["cur_round_total_bet"] = tCurTotalBet, ["cur_round_max_raise"] = tMaxRaise };
                        local tOtherHead = {                                                                                                    
                                        ["command"] = "CLIENT_OTHER_CALL",
                                        ["user_conn_id"] = 0,                    
                                        ["user_id"] = 0, 
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserCall", tOtherBody)                                
                        }
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserCall", tOtherBody)
			local tFirst = setPlayerConn(t["user_id"], tOtherHead["others_conn_id"], tTable, nil);
			if tFirst ~= nil then
                        	sendPkg(tOtherHead)
			end
			tCallRes["side_pool"] = tOtherBody["side_pool"];
			tCallRes["main_pool"] = tOtherBody["main_pool"];
			tCallRes["cur_round_total_bet"] = tCurTotalBet;
			tCallRes["cur_round_max_raise"] = tMaxRaise;
        		t["serialized"] = protobuf.encode("ClientGate.UserCallResponse", tCallRes)
        		sendPkg(t);
        		endGame(tTable, tTimerType, tEndRet);
                end
        end
end

function onRaise(t, flag)
print("DEBUG, onRaise." .. t["user_id"])
        local tTable = GetTableByPlayer(t["user_id"]);
        local tRaiseRes = {
                ["result"] = "enumResultSucc",
                ["money"] = 0,
                ["next_user_id"] = "",
		["side_pool"] = {},
		["main_pool"] = 0
        }
        if tTable ~= nil then
		local tRaiseReqBody = protobuf.decode("ClientGate.UserRaise", t["serialized"]);
		t["command"] = "CLIENT_RAISE_RESPONSE";
        	t["others_conn_id"] = {}

		local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
		local tRet, tRaiseBet = OnRaise(t["user_id"], tRaiseReqBody["multi"], tTable);
                if tRet > 0 then
                        tRaiseRes["result"] = "enumResultFail";
			t["serialized"] = protobuf.encode("ClientGate.UserRaiseResponse", tRaiseRes)
			print("Raise fail, errno :" .. tRet)
        		sendPkg(t);
                else
printTable(tTable)
			stopTimerByPlayer(t["user_id"]);
			local tTimerType = "CommonBet";
			local tEndRet = isEndGame(tTable, tTimerType);

			if flag == 0 then
				tTable["AutoOperate"][tCurIndex] = 0;
			else
				if tTable["AutoOperate"][tCurIndex] == nil then
					tTable["AutoOperate"][tCurIndex] = 1;
				else
					tTable["AutoOperate"][tCurIndex] = tTable["AutoOperate"][tCurIndex] + 1;
				end
			end
                        local tPlayers = tTable["Players"];
			local tNextPlayer = "";
			if tTable["Gameing"] == 1 and tEndRet == 0 then
                        	tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
			end
			local tCurIndex, tCurPlayer = GetPlayerIndex(t["user_id"], tTable);
			local tCurMoney = tRaiseBet;
			local tCurTotalBet = tPlayers[tTable["CurPlayer"]]["CurBet"];
			local tMaxRaise = tTable["CurMaxBet"];
                        -- 组合响应包
                        tRaiseRes["money"] = tCurMoney;
                        tRaiseRes["next_user_id"] = tNextPlayer;

                        -- 其他玩家     
                        local tOtherBody = {["user_id"] = t["user_id"], ["money"] = tCurMoney, ["next_user_id"] = tNextPlayer, ["cur_round_total_bet"] = tCurTotalBet, ["cur_round_max_raise"] = tMaxRaise };
                        local tOtherHead = {
                                        ["command"] = "CLIENT_OTHER_RAISE",
                                        ["user_conn_id"] = 0,
                                        ["user_id"] = 0,
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserRaise", tOtherBody)
                        }
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserRaise", tOtherBody)
			local tFirst = setPlayerConn(t["user_id"], tOtherHead["others_conn_id"], tTable, nil);
			if tFirst ~= nil then
                        	sendPkg(tOtherHead)
			end

			tRaiseRes["side_pool"] = tOtherBody["side_pool"];
			tRaiseRes["main_pool"] = tOtherBody["main_pool"];
			tRaiseRes["cur_round_total_bet"] = tCurTotalBet;
			tRaiseRes["cur_round_max_raise"] = tMaxRaise;
print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" .. tCurTotalBet .. "~~~~~~~~~~~~~" .. tMaxRaise)

        		t["serialized"] = protobuf.encode("ClientGate.UserRaiseResponse", tRaiseRes)
        		sendPkg(t);
        		endGame(tTable, tTimerType, tEndRet);
                end
        end
end

function onBuyItem(t)
print("DEBUG, onBuyItem")
	local tUid = t["user_id"];
	local tTable = GetTableByPlayer(tUid);
	local tIndex, tPlayer = GetPlayerIndex(tUid, tTable);
	local tBuyItemReqBody = protobuf.decode("ClientGate.UseItem", t["serialized"]);

	local tItemPrice = tTable["TableInfo"]["ItemPrice"];

	local tBuyRes = { ["result"] = "enumResultSucc", ["other_user_id"] = tBuyItemReqBody["other_user_id"], ["item_type"] = tBuyItemReqBody["item_type"] }
	if tPlayer["Money"] > tItemPrice then	-- 购买成功
		tPlayer["Money"] = tPlayer["Money"] - tItemPrice;
		buyItem(tUid, tItemPrice)

		local tOtherBody = {["user_id"] = t["user_id"], ["other_user_id"] = tBuyItemReqBody["other_user_id"], ["item_type"] = tBuyItemReqBody["item_type"] };
		local tOtherHead = {
                                ["command"] = "CLIENT_OTHER_USE_ITEM",
                                ["user_conn_id"] = 0,
                                ["user_id"] = 0,
                                ["others_conn_id"] = {},
		}
                tOtherHead.serialized = protobuf.encode("ClientGate.OtherUseItem", tOtherBody)
		local tFirst = setPlayerConn(t["user_id"], tOtherHead["others_conn_id"], tTable, nil);
		if tFirst ~= nil then
                	sendPkg(tOtherHead)
		end
	else					-- 购买失败
		tBuyRes["result"] = "enumResultFail";
	end
	t["command"] = "CLIENT_USE_ITEM_RESPONSE";
	t["others_conn_id"] = {};
	t["serialized"] = protobuf.encode("ClientGate.UseItemResponse", tBuyRes);
	sendPkg(t);
end

function onOpenBox(t)
	local tOpenReq = protobuf.decode("ClientGate.OpenBox", t["serialized"]);
	local tUid = t["user_id"];
	local tBoxLevel = tOpenReq["box_type"];
	local tRet = nil;

	local tBasicInfo = GetPlayerBasicInfo(tUid);
	local tCurAct = RedisGetTotalActivity(tUid, "ActDailyMax");
	local tConfig = Act_BoxConfig[tBoxLevel];
	if tConfig ~= nil then
		if tCurAct >= tConfig[1] then
			local tCondition = "OpenBox_level" .. tBoxLevel;
			local tCount = RedisGetOpenBoxCount(uid, tCondition);
			if tCount == 1 then
				tBasicInfo["user_score"] = tBasicInfo["user_score"] + tConfig[2];
				sendSaveData(uid, "balance", tConfig[2]);
				tRet = 0;
			end
		end
	end

	local tOpenRes = { ["result"] = "enumResultFail", ["add_money"] = 0 }
	if tRet ~= nil then
		tOpenRes["result"] = "enumResultSucc";
		tOpenRes["add_money"] = tConfig[2];
	end

	t["command"] = "CLIENT_OPEN_BOX_RESPONSE";
        t["others_conn_id"] = {};
        t["serialized"] = protobuf.encode("ClientGate.OpenBoxResponse", tOpenRes);
	sendPkg(t);
end

function OnPlayerTimerOut(tableId)
print("DEBUG, onPlayerTimerOut.")
        local tTable = GetTableByTableId(tableId);
	local tPlayer = tTable["Players"][tTable["CurPlayer"]];
	local tUid = tPlayer["Uid"];
	local tConn = getPlayerConnect(tUid);
	
print("TimerOut, tid:" .. tableId .. ", uid:" .. tUid)
	local tFlag = tTable["AutoOperate"][tTable["CurPlayer"]];
	if tPlayer["CurBet"] >= tTable["CurMaxBet"] and (tFlag == nil or tFlag < 1) then
		setPlayerCall(tUid, tConn);
	else
		setPlayerFlod(tUid, tConn);
	end
end

function OnSendSidePool(tableInfo)

end

function OnSendDownCards(tableInfo)
print("DEBUG, onSendDownCards")
	local tStep = tableInfo["Steps"];
	if tStep == 0 then
		return nil;
	end

	local tCardsBody = {
		["start_user_id"] = tableInfo["Players"][tableInfo["CurPlayer"]]["Uid"],
		["card"] = {}
	}
	if tStep == 1 then
		for i = 1, 3 do
			table.insert(tCardsBody["card"], tableInfo["DownCards"][i]);
		end 
	elseif tStep == 2 then
		table.insert(tCardsBody["card"], tableInfo["DownCards"][4]);
	elseif tStep == 3 then
		table.insert(tCardsBody["card"], tableInfo["DownCards"][5]);
	end

	tCardsBody["main_pool"], _, tCardsBody["side_pool"], _ = RoundSidePool(tableInfo);

	local tCardsHead = {
                ["command"] = "DOWN_CARDS_TO_CLIENT",
                ["user_conn_id"] = 0,
                ["user_id"] = 0,
                ["others_conn_id"] = {},
	}
        tCardsHead.serialized = protobuf.encode("ClientGate.CardToUser", tCardsBody)

	local tFirst = setPlayerConn(nil, tCardsHead["others_conn_id"], tableInfo, nil);
	if tFirst ~= nil then
		sendPkg(tCardsHead);
	end
end

function OnSettle(tableInfo)
print("DEBUG, onSettle")
	local tPlayers = tableInfo["Players"];
	local tSettleBody = { ["info"] = {} }
	local tSettleHead = {
                        ["command"] = "SETTLE_TO_CLIENT",
                        ["user_conn_id"] = 0,
                        ["user_id"] = 0,
                        ["others_conn_id"] = {},
        }
	for i, v in pairs(tableInfo["EndCardInfo"]) do
		local tWinFlag = 0;
		if tableInfo["Wins"][i] ~= nil then
			tWinFlag = 1;
		end
		local tInfo = { ["index"] = i, ["money"] = tPlayers[i]["Money"], ["card_level"] = v["Level"], ["win_flag"] = tWinFlag, ["cards"] = v["Card"], ["own_cards"] = tPlayers[i]["OwnCard"] }
		table.insert(tSettleBody["info"], tInfo);
	end
	tSettleBody["main_pool"], _, tSettleBody["side_pool"], _ = RoundSidePool(tableInfo);
	tSettleBody["distribution_info"] = tableInfo["WinPoolMoney"];
	if tableInfo["Surplus"] > 1 then
		tSettleBody["down_cards"] = tableInfo["DownCards"];
	end

	local tFirst = setPlayerConn(nil, tSettleHead["others_conn_id"], tableInfo, nil);
	tSettleHead["serialized"] = protobuf.encode("ClientGate.SettleToUser", tSettleBody);

	-- 增加金额
	local tAddMoneyPlayers = { ["money_info"] = {} }
	for i, v in pairs(tableInfo["Players"]) do
		if v["InGameing"] == 1 then
			if v["Flod"] == 0 then
				playerSettle(v["Uid"], i, v, tableInfo);
			end

			local tPlayerTable = GetOffPlayer(v["Uid"]);
			if tPlayerTable ~= nil then
				sendOtherPlayerLeave(v["Uid"], tableInfo);
				--sendPlayerLeave(v["Uid"]);
				RemovePlayer(v["Uid"], tableInfo);
				RemoveOffPlayer(v["Uid"]);
			else
				if v["Money"] < tableInfo["TableInfo"]["MinMoney"] then
					local tAddMoney = addMoney(v["Uid"], v, tableInfo);
					if v["Money"] < tableInfo["TableInfo"]["MinMoney"] then
						sendOtherPlayerLeave(v["Uid"], tableInfo);
						sendPlayerLeave(v["Uid"]);
						RemovePlayer(v["Uid"], tableInfo);
						--table.insert(tRemovePlayers, v["Uid"])
					else
						local tPlayerMoney = { ["user_id"] = v["Index"], ["money"] = tAddMoney }
print("game end, add money :" .. tPlayerMoney["user_id"] .. ", money :" .. tPlayerMoney["money"])
                                                table.insert(tAddMoneyPlayers["money_info"], tPlayerMoney);
					end
				end
			end
		end
	end

	sendPkg(tSettleHead);

	local tAddMoneySize = table_size(tAddMoneyPlayers["money_info"]);
print("add size : " .. tAddMoneySize);
	if tAddMoneySize > 0 then
		local tAddMoneyHead = {
                        ["command"] = "CLIENT_TABLE_ADD_MONEY",
                        ["user_conn_id"] = 0,
                        ["user_id"] = 0,
                        ["others_conn_id"] = {}
                }
		tAddMoneyHead["serialized"] = protobuf.encode("ClientGate.AddTableMoney", tAddMoneyPlayers);
		local tFirst = setPlayerConn(nil, tAddMoneyHead["others_conn_id"], tableInfo, nil);
		if tFirst ~= nil then
			sendPkg(tAddMoneyHead);
		end
	end

	-- start StartGame timer
	startGameTimer(tableInfo);
	EndResetTable(tableInfo);
end

function OnStartGame(tid)
print("DEBUG, onStartGame. tid :" .. tid)
	local tTable = GetTableByTableId(tid);
	if tTable ~= nil then
		local tRet = StartTable(tTable);
		if tRet == 0 then
printTable(tTable)
			stopTimerByTable(tid);
			local tStartHead = {
                                        ["command"] = "DEAL_TO_CLIENT",
                                        ["user_conn_id"] = 0,
                                        ["user_id"] = 0,
                                        ["others_conn_id"] = {}
			}
			local tPlayers = tTable["Players"];
			local tStartBody = {
				["card_a"] = 0,
				["card_b"] = 0,
				["button_user_id"] = tPlayers[tTable["ButtonPlayer"]]["Uid"],
				["small_user_id"] = tPlayers[tTable["SmallPlayer"]]["Uid"],
				["big_user_id"] = tPlayers[tTable["BigPlayer"]]["Uid"],
				["start_user_id"] = tPlayers[tTable["CurPlayer"]]["Uid"],
				["small_stakes"] = tTable["TableInfo"]["SmallBlinds"],
				["big_stakes"] = tTable["TableInfo"]["BigBlinds"]
			};
			for i, v in pairs(tPlayers) do
				tStartBody["card_a"] = v["OwnCard"][1];
				tStartBody["card_b"] = v["OwnCard"][2];

				tStartHead["user_conn_id"] = getPlayerConnect(v["Uid"]);
				tStartHead["user_id"] = v["Uid"];
				tStartHead["serialized"] = protobuf.encode("ClientGate.DealToUser", tStartBody);

				sendPkg(tStartHead);
			end
			endGame(tTable, "DealBet", 0);
		else
			print("StartTable fail, errno :" .. tRet)
		--	startGameTimer(tTable);
		end
	else
		stopTimerByTable(tid);
	end
end

function OnUserData(packet)
	local t = protobuf.decode("PB.ForwardingPacket", packet);
	if t == nil then
		return nil;
	end

	print('recv packet ' .. t.command)

	if t.command == "CLIENT_ENTER_GAME" then
		onEnter(t);
	elseif t.command == "CLIENT_LEAVE_GAME" then
		onLeave(t);
	elseif t.command == "CLIENT_FOLD" then
		onFlod(t, 0);
	elseif t.command == "CLIENT_CALL" then
		onCall(t, 0);
	elseif t.command == "CLIENT_RAISE" then
		onRaise(t, 0);
	elseif t.command == "CLIENT_USE_ITEM_REQUECT" then
		onBuyItem(t);
	elseif t.command == "USER_DISCONNECTED_TO_CL" then
		onLeave(t);
	elseif t.command == "CLIENT_OPEN_BOX" then
		onOpenBox(t)
	elseif t.command == "CLIENT_LOOK_TABLE" then
		onLook(t)
	end
	
--    hex_dump(packet)
end
