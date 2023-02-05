require("logic.TaxasTable")
require("logic.TaxasPlayer")


function RedisGetPlayerInfo(uid)
	local tPlayer = createPlayer();
	tPlayer["Uid"] = uid;
	tPlayer["Money"] = 1000;

	local tBasicInfo = {
		["user_id"] = uid,
		["nick"] = "test",
		["avatar"] = "test",
		["gender"] = "enumGenderFemale",
		["user_score"] = 2222,
		["experience"] = 3333,
	}
	SetPlayerBasicInfo(uid, tBasicInfo);

	return tPlayer;
end
