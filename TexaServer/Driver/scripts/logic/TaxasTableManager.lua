require("logic.TaxasTable")
require("logic.TaxasLogic")

-- 桌子管理
TaxasTableManager = {}	-- [tid] = table
TaxasPlayerTable = {}	-- [uid] = table

function GetTableByTableId(tid)
	return TaxasTableManager[tid];
end

function GetTableByPlayer(uid)
	return TaxasPlayerTable[uid];
end

function getTable(tableId, config)
	local tTable = TaxasTableManager[tableId];
	if tTable == nil then
		--InitTable();
		local tConfig = parseTableConfig(config);
		tTable = createTable(tConfig, tableId);
print("new table, id :" .. tTable["TableId"])
		TaxasTableManager[tableId] = tTable;
	end

	return tTable;
end

function PlayerLookTable(uid, tableId, config, basicInfo)
	local tTable = getTable(tableId, config);
	LookTable(uid, tTable, basicInfo);
end

function PlayerEnterTable(uid, tableId, config, basicInfo, index)
	local tTable = getTable(tableId, config);
	local tRet = EnterTable(uid, tTable, basicInfo, index);
	if tRet == 0 then
		TaxasPlayerTable[uid] = tTable;
	else
		print("Enter errno :" .. tRet)
	end
	
	return tRet;
end

function PlayerLeaveOutTable(uid)
	local tTable = GetTableByPlayer(uid);
	
	local tRet = 100000;

	if tTable ~= nil then
		tRet = LeaveTable(uid, tTable);
		if tRet == 0 then
			TaxasPlayerTable[uid] = nil;
		end
	end

	return tRet;
end

