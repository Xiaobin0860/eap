require("logic.TaxasTableManager")
require("logic.TaxasConfig")
require("logic.TaxasPlayer")

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
	local tUid = AllPlayerId[conn];
	AllPlayerId[conn] = nil;
	AllPlayersConn[tUid] = nil;
end

function getPlayerConnect(uid)
	return AllPlayersConn[uid];
end

function getPlayerId(conn)
	return AllPlayersId[conn];
end

function sendPkg(pkg)
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

function stopTimerByPlayer(uid, func, time)
	local tTable = GetTableByPlayer(uid);
	
	local driver = GetDriver()
        driver:StopTimer(AllTimer[tTable["TableId"]]);
	table.remove(AllTimer, tTable["TableId"]);
end

function startTimerByTable(tableId, func, time)
	if AllTimer[tableId] ~= nil then
		return nil;
	end

	local driver = GetDriver()
	AllTimer[tableId] = driver:StartTimer(tableId, func, time);
end

function stopTimerByTable(tableId)
	local driver = GetDriver()
        driver:StopTimer(AllTimer[tableId]);
	table.remove(AllTimer, tableId);
end

function endGame(tableInfo)
	if tableInfo["Gameing"] == 0 then
        	OnSettle(tableInfo);
        else
		if tableInfo["CurCards"] < tableInfo["Steps"] then
			tableInfo["CurCards"] = tableInfo["CurCards"] + 1;
			OnSendDownCards(tableInfo);
		end
        	startTimerByPlayer(tableInfo["Players"][tableInfo["CurPlayer"]]["Uid"], "OnPlayerTimerOut", PlayerBetTimer);
	end
end

function startGameTimer(tableInfo)
	if tableInfo["Gameing"] == 0 and tableInfo["PlayerCount"] >= tableInfo["TableInfo"]["MinPlayerCount"] then
                startTimerByTable(tableInfo["TableId"], "OnStartGame", PlayerBetTimer);
        end
end

Test_user = "1";
aa = 0;

function onEnter(t)
	local tEnterReq = protobuf.decode("ClientGate.EnterGameRequest", t["serialized"]);
        local tEnterRes = {
                ["result"] = "enumResultSucc",
                ["user_info"] = {}
	 };
	aa = aa + 1;
	t["user_id"] = Test_user;
	for i = 1, aa do
		t["user_id"] = t["user_id"] .. "2";
	end

        print('test ' .. t["user_conn_id"] .. ' ' .. t["user_id"])

        setPlayerConnect(t["user_conn_id"], t["user_id"]);
	-- 进入桌子

        if PlayerEnterTable(t["user_id"], tEnterReq["room_id"], tEnterReq["desc"]) ~= 0 then
                tEnterRes["result"] = "enumResultFail";
        else

		-- 返回桌子玩家信息
                local tTable = GetTableByTableId(tEnterReq["room_id"]);                  
                if tTable ~= nil then                           
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

			local tFirst = nil;
                        for i, v in pairs(tTable["Players"]) do
				if v["Uid"] ~= t["user_id"] then
					-- 组合响应包
					local tBaseInfo = GetPlayerBasicInfo(v["Uid"]);
					local tTableInfo = v;
					local tPlayerInfo = { ["user_base"] = tBaseInfo, ["user_table"] = tTableInfo};
					table.insert(tEnterRes["user_info"], tPlayerInfo);

					-- 组合other响应包
					tFirst = 1;
					table.insert(tOtherHead["others_conn_id"], getPlayerConnect(v["Uid"]));
				else
					tOtherBody["user_info"] = { ["user_base"] = GetPlayerBasicInfo(t["user_id"]), ["user_table"] = v };
				end
                        end

			if tFirst ~= nil then
                        	tOtherHead.serialized = protobuf.encode("ClientGate.OtherEnterGameResponse", tOtherBody)
				-- 发other响应包
				sendPkg(tOtherHead)
			end
                end

		startGameTimer(tTable);
        end

	-- 玩家加入
        t["command"] = "CLIENT_ENTER_GAME_RESPONSE";
	t["others_conn_id"] = {}
        t["serialized"] = protobuf.encode("ClientGate.EnterGameResponse", tEnterRes);
	-- 发响应包
	sendPkg(t)
end

function onLeave(t)
	if PlayerLeaveOutTable(t["user_id"]) == 0 then
		-- 其他玩家
                local tOtherBody = {["user_id"] = t["user_id"]};
                local tOtherHead = {
                                ["command"] = "CLIENT_OTHER_LEAVE_GAME",
                                ["user_conn_id"] = 0,
                                ["user_id"] = 0,
                                ["others_conn_id"] = {},
                                --["serialized"] = protobuf.encode("ClientGate.OtherLeaveGame", tOtherBody)
                }
                tOtherHead.serialized = protobuf.encode("ClientGate.OtherLeaveGame", tOtherBody)

                local tTable = GetTableByPlayer(t["user_id"]);                  
		local tFirst = nil;
		for i, v in pairs(tTable["Players"]) do
			if v["Uid"] ~= t["user_id"] then
				-- 组合other响应包
                               	tFirst = 1;
                               	table.insert(tOtherHead["others_conn_id"], getPlayerConnect(v["Uid"]));
			end
		end
		if tFirst ~= nil then
			sendPkg(tOtherHead);
		end

		clearPlayerConnect(t["user_conn_id"]);
		RemovePlayerBasicInfo(t["user_id"]);
	end
end

function onFlod(t)
	local tTable = GetTableByPlayer(t["user_id"]);
	local tFlodRes = {
		["result"] = "enumResultSucc",
		["next_user_id"] = ""
	}
	if tTable ~= nil then
		stopTimerByPlayer(t["user_id"]);
		if OnFlod(t["user_id"], tTable) ~= 0 then
			tFlodRes["result"] = "enumResultFail";
		else
			local tPlayers = tTable["Players"];
			local tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
			-- 组合响应包
			tFlodRes["next_user_id"] = tNextPlayer;

			-- 其他玩家
			local tOtherBody = {["user_id"] = t["user_id"], ["next_user_id"] = tNextPlayer};
			local tOtherHead = {
					["command"] = "CLIENT_OTHER_FLOD",
					["user_conn_id"] = 0,
                                        ["user_id"] = 0,
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserFlod", tOtherBody)
			}
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserFlod", tOtherBody)
			for i, v in pairs(tPlayers) do
				if v["Uid"] ~= t["user_id"] then
					-- 组合other响应包                      	
                               		tFirst = 1;
                               		table.insert(tOtherHead["others_conn_id"], getPlayerConnect(v["Uid"]));
				end
			end
			if tFirst ~= nil then
				sendPkg(tOtherHead)
			end
		end

        	t["command"] = "CLIENT_FOLD_RESPONSE";
        	t["others_conn_id"] = {}
        	t["serialized"] = protobuf.encode("ClientGate.UserFlodResponse", tFlodRes)
        	sendPkg(t);

        	endGame(tTable);
	end
end

function onCall(t)
	local tTable = GetTableByPlayer(t["user_id"]);
	local tCallRes = {
                ["result"] = "enumResultSucc",
		["money"] = 0,
                ["next_user_id"] = ""
        }
        if tTable ~= nil then
		stopTimerByPlayer(t["user_id"]);
                if OnCall(t["user_id"], tTable) ~= 0 then
                        tCallRes["result"] = "enumResultFail";
                else
                        local tPlayers = tTable["Players"];
                        local tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
			local tCurMoney = tPlayers[GetPlayerIndex(t["user_id"], tTable)]["Money"];
                        -- 组合响应包
			tCallRes["money"] = tCurMoney;
                        tCallRes["next_user_id"] = tNextPlayer;

                        -- 其他玩家     
                        local tOtherBody = {["user_id"] = t["user_id"], ["money"] = tCurMoney, ["next_user_id"] = tNextPlayer};
                        local tOtherHead = {                                                                                                    
                                        ["command"] = "CLIENT_OTHER_CALL",
                                        ["user_conn_id"] = 0,                    
                                        ["user_id"] = 0, 
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserCall", tOtherBody)                                
                        }
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserCall", tOtherBody)
                        for i, v in pairs(tPlayers) do                                                                                          
				if v["Uid"] ~= t["user_id"] then
                                	-- 组合other响应包      
                               	        tFirst = 1;                              
                               	        table.insert(tOtherHead["others_conn_id"], getPlayerConnect(v["Uid"]));
				end
                        end
			if tFirst ~= nil then
                        	sendPkg(tOtherHead)
			end
                end
        	t["command"] = "CLIENT_CALL_RESPONSE";
        	t["others_conn_id"] = {}
        	t["serialized"] = protobuf.encode("ClientGate.UserCallResponse", tFlodRes)
        	sendPkg(t);

        	endGame(tTable);
        end
end

function onRaise(t)
        local tTable = GetTableByPlayer(t["user_id"]);
        local tRaiseRes = {
                ["result"] = "enumResultSucc",
                ["money"] = 0,
                ["next_user_id"] = ""
        }
        if tTable ~= nil then
		stopTimerByPlayer(t["user_id"]);
		local tRaiseReqBody = protobuf.decode("ClientGate.UserRaise", t["serialized"]);
                if OnRaise(t["user_id"], tRaiseReqBody["multi"], tTable) ~= 0 then
                        tCallRes["result"] = "enumResultFail";
                else
                        local tPlayers = tTable["Players"];
                        local tNextPlayer = tPlayers[tTable["CurPlayer"]]["Uid"];
	                local tCurMoney = tPlayers[GetPlayerIndex(t["user_id"], tTable)]["Money"];
                        -- 组合响应包
                        tRaiseRes["money"] = tCurMoney;
                        tRaiseRes["next_user_id"] = tNextPlayer;

                        -- 其他玩家     
                        local tOtherBody = {["user_id"] = t["user_id"], ["money"] = tCurMoney, ["next_user_id"] = tNextPlayer};
                        local tOtherHead = {
                                        ["command"] = "CLIENT_OTHER_RAISE",
                                        ["user_conn_id"] = 0,
                                        ["user_id"] = 0,
                                        ["others_conn_id"] = {},
                                        --["serialized"] = protobuf.encode("ClientGate.OtherUserRaise", tOtherBody)
                        }
                        tOtherHead.serialized = protobuf.encode("ClientGate.OtherUserRaise", tOtherBody)
                        for i, v in pairs(tPlayers) do
				if v["Uid"] ~= t["user_id"] then
                                	-- 组合other响应包 
                               	        tFirst = 1;
                               	        table.insert(tOtherHead["others_conn_id"], getPlayerConnect(v["Uid"]));
				end
                        end
			if tFirst ~= nil then
                        	sendPkg(tOtherHead)
			end
                end
		t["command"] = "CLIENT_RAISE_RESPONSE";
        	t["others_conn_id"] = {}
        	t["serialized"] = protobuf.encode("ClientGate.UserRaiseResponse", tFlodRes)
        	sendPkg(t);

        	endGame(tTable);
        end
end

function OnPlayerTimerOut(tableId)
        local tTable = GetTableByTableId(tableId);
	
	local tFlodHead = {
                        ["command"] = "CLIENT_FLOD",
                        ["user_conn_id"] = 0,
                        ["user_id"] = tTable["Players"][tTable["CurPlayer"]]["Uid"],
                        ["others_conn_id"] = {},
        }
	onFlod(tFlodHead);
end

function OnSendDownCards(tableInfo)
	local tStep = tableInfo["Steps"];
	if tStep == 0 then
		return nil;
	end

	local tCardsBody = {
		["start_user_id"] = tableInfo["CurPlayer"],
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

	local tCardsHead = {
                ["command"] = "DOWN_CARDS_TO_CLIENT",
                ["user_conn_id"] = 0,
                ["user_id"] = 0,
                ["others_conn_id"] = {},
                --["serialized"] = protobuf.encode("ClientGate.CardToUser", tCardsBody);
	}
        tCardsHead.serialized = protobuf.encode("ClientGate.CardToUser", tCardsBody)

	local tPlayers = tableInfo["Players"];
	local tFirst = nil;
	for i, v in pairs(tPlayers) do
		tFirst = 1;
                table.insert(tCardsHead["others_conn_id"], getPlayerConnect(v["Uid"]));
	end
	if tFirst ~= nil then
		sendPkg(tCardsHead);
	end
end

function OnSettle(tableInfo)
	local tPlayers = tableInfo["Players"];
	local tSettleBody = { ["winPlayerCards"] = {}, ["playerMoneys"] = {} }
	local tSettleHead = {
                        ["command"] = "SETTLE_TO_CLIENT",
                        ["user_conn_id"] = 0,
                        ["user_id"] = 0,
                        ["others_conn_id"] = {},
        }
	for i, v in pairs(tableInfo["Wins"]) do
		local tInfo = { ["key"] = i, ["cards"] = v }
		table.insert(tSettleBody["winPlayerCards"], tInfo);
	end

	local tFirst = nil;
	for i, v in pairs(tPlayers) do
		local tInfo = { ["key"] = v["Index"], ["value"] = v["Money"] }
		table.insert(tSettleBody["playerMoneys"], tInfo);

                tFirst = 1;
                table.insert(tSettleHead["others_conn_id"], getPlayerConnect(v["Uid"]));
        end

	tSettleHead["serialized"] = protobuf.encode("ClientGate.SettleToUser", tSettleBody);

	sendPkg(tSettleHead);

	-- start StartGame timer
	startGameTimer(tableInfo);
end

function OnStartGame(tid)
	local tTable = GetTableByTableId(tid);
	if tTable ~= nil then
		if StartTable(tTable) == 0 then
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
			endGame(tTable);
		else
			startGameTimer(tTable);
		end
	end
end

function OnUserData(packet)
	local t = protobuf.decode("PB.ForwardingPacket", packet);
	if t == nil then
		return nil;
	end

	print('recv packet ' .. t.command)

	if t.command == "CLIENT_ENTER_GAME" then
		print("!!!!!!!!!!!!")
		onEnter(t);
	elseif t.command == "CLIENT_LEAVE_GAME" then
		print("!!!!!!!!!!!!")
		onLeave(t);
	elseif t.command == "CLIENT_FOLD" then
		print("!!!!!!!!!!!!")
		onFlod(t);
	elseif t.command == "CLIENT_CALL" then
		print("!!!!!!!!!!!!")
		onCall(t);
	elseif t.command == "CLIENT_RAISE" then
		print("!!!!!!!!!!!!")
		onRaise(t);
	elseif t.command == "" then
		
	end
	
--    hex_dump(packet)
end
