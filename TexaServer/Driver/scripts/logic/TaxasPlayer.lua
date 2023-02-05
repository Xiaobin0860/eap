

--PlayerBasicInfo = {
--	["user_id"] = uid,
--	["nick"] = "test",
--	["avatar"] = "test",
--	["gender"] = "enumGenderFemale",
--	["user_score"] = 2222,
--	["experience"] = 3333,
--}

-- 玩家管理
TaxasPlayerBasic = {}   -- [uid] = basic
function GetPlayerBasicInfo(uid)
	return TaxasPlayerBasic[uid];
end

function SetPlayerBasicInfo(uid, basic)
	TaxasPlayerBasic[uid] = basic;
end

function RemovePlayerBasicInfo(uid)
	TaxasPlayerBasic[uid] = nil;
end

OffPlayers = {}		-- [uid] = table
function GetOffPlayer(uid)
	return OffPlayers[uid];
end

function SetOffPlayer(uid, tableInfo)
	OffPlayers[uid] = tableInfo;
end

function RemoveOffPlayer(uid)
	OffPlayers[uid] = nil;
end
