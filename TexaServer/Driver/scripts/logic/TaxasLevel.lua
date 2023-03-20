require("logic.TaxasPlayer")
require("logic.TaxasConfig")

function compDailyExp(uid, addExp)
	local tAddExp = addExp;
	local tExp = 0;
	local tBasicInfo = GetPlayerBasicInfo(uid);
	if tBasicInfo ~= nil then
		tExp = RedisGetDailyExp(uid, tAddExp);
		for i, v in pairs(Exp_DailyMax["MaxExp"]) do
			if tBasicInfo["experience"] <= v then
				tExp = Exp_DailyMax["DailyMax"][i] - tExp;
				break;
			end
		end

		if tExp > 3 then
			tExp = tAddExp;
		elseif tExp < 0 and tExp > -4 then
			tExp = math.abs(tExp);
		elseif tExp <= -4 then
			tExp = 0;
		end
	end

	return tExp;
end

function LoseGameExp(uid, basic)
	local tExp = compDailyExp(uid, 3);
	basic["experience"] = basic["experience"] + tExp;

	return tExp;
end

function WinGameExp(uid, basic, tableInfo)
	local tAddExp = math.floor(TableExpCfg[tableInfo["TableInfo"]["Type"]] * tableInfo["PlayerCount"] / 3 + 3 + 0.5);

	tAddExp = compDailyExp(uid, tAddExp);

	basic["experience"] = basic["experience"] + tAddExp;
	return tAddExp;
end

function AddActByPlayiCommon(uid, index, player, tableInfo)
	local tAddAct = 0;

	local tTableInfo = tableInfo["TableInfo"];
	if isRoomLevel1(tTableInfo["Type"]) == 0 then
		if tableInfo["Wins"][index] == nil then
			local tCount = RedisGetLevel1_Play(uid);
			if tCount <= Liveness["Level1_Play"]["Count"] then
				tAddAct = tAddAct + Liveness["Level1_Play"]["Value"];
			end
		else
			local tCount = RedisGetLevel1_Win(uid);
			if tCount <= Liveness["Level1_Win"]["Count"] then
				tAddAct = tAddAct + Liveness["Level1_Win"]["Value"];
			end
		end
	elseif isRoomLevel2(tTableInfo["Type"]) == 0 then
		if tableInfo["Wins"][index] == nil then
        		local tCount = RedisGetLevel1_Play(uid);
        		if tCount <= Liveness["Level2_Play"]["Count"] then
        			tAddAct = tAddAct + Liveness["Level2_Play"]["Value"];
        		end
        	else
        		local tCount = RedisGetLevel1_Win(uid);
        		if tCount <= Liveness["Level2_Win"]["Count"] then
        			tAddAct = tAddAct + Liveness["Level2_Win"]["Value"];
			end
		end
	end

	local tMoney = player["Money"] - tableInfo["StartMoney"][index];
	if tMoney >= 10000 then
		local tCount = RedisGetWin10000(uid);
		if tCount <= Liveness["Win10000"]["Count"] then
			tAddAct = tAddAct + Liveness["Win10000"]["Value"];
		end
	end

	return tAddAct;
end
