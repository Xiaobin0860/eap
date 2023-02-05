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

function PlayerEnterTable(uid, tableId, config)
	local tTable = TaxasTableManager[tableId];
	if tTable == nil then
		InitTable();
		local tConfig = parseTableConfig(config);
		tTable = createTable(tConfig, tableId);
		TaxasTableManager[tableId] = tTable;
	end

	local tRet = EnterTable(uid, tTable);
	if tRet == 0 then
		TaxasPlayerTable[uid] = tTable;
	end
	
	return tRet;
end

function PlayerLeaveOutTable(uid)
	local tTable = GetTableByPlayer(uid);
	
	local tRet = 100000;

	if tTable ~= nil then
		tRet = LeaveTable(uid, tTable);
		if tRet == 0 then
			table.remove(TaxasPlayerTable, uid);
		end
	end

	return tRet;
end

