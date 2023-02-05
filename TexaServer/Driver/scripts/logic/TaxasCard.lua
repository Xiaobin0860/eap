require("logic.TaxasTable")

ALLCard = {
	2,2,2,2,		-- 1-4
	3,3,3,3,		-- 5-8
	4,4,4,4,		-- 9-12
	5,5,5,5,		-- 13-16
	6,6,6,6,		-- 17-20
	7,7,7,7,		-- 21-24
	8,8,8,8,		-- 25-28
	9,9,9,9,		-- 29-32
	10,10,10,10,		-- 33-36
	11,11,11,11,		-- 37-40
	12,12,12,12,		-- 41-44
	13,13,13,13,		-- 45-48
	14,14,14,14,		-- 49-52
}

Shunzi = {}			-- [card] = {index, index}
Duizi = {}			-- [card] = {index, index}
ColorPai = {}			-- [color] = {index, index}
CardLevel = {
	["Level"] = 0,
	["Card"] = {}
}

-- 获取牌的颜色
function colorCard(index)
	local color = 1;
	while 1 do
		local tCard = index - color;
		if tCard == 0 or tCard % 4 == 0 then
			return color;
		end
		color = color + 1;
	end
	return nil;
end

-- 筛选牌
function screenCard(orderCards)
	local tPreCard = {["index"] = 0, ["card"] = 0, ["start"] = 0};
	local tLianStart = {["start"] = 0, ["pre"] = 0};
        for i, v in pairs(orderCards) do
		local tCurIndex = v;
		local tCurCard = ALLCard[v];
        	-- 处理颜色
        	local tColor = colorCard(tCurIndex);
        	if ColorPai[tColor] == nil then
        		local tColors = {tCurIndex};
        		ColorPai[tColor] = tColors;
        	else
        		table.insert(ColorPai[tColor], tCurIndex);
        	end
                                                                                  
        	if tPreCard["card"] == tCurCard then		-- 处理对子
        		if Duizi[tCurCard] == nil then
        			local tDuizi = {tPreCard["index"], tCurIndex};
        			Duizi[tCurCard] = tDuizi;
        		else
        			table.insert(Duizi[tCurCard], tCurIndex);
        		end
        	else					-- 处理链子
        		if tPreCard["card"] ~= 0 and (tCurCard - tPreCard["card"]) == 1 then
				if tLianStart["pre"] == 0 or tLianStart["pre"] ~= tPreCard["card"] then
					tLianStart["pre"] = tPreCard["card"];
					tLianStart["start"] = tPreCard["card"];
				end

        			if Shunzi[tLianStart["start"]] == nil then
        				local tLian = {tPreCard["index"], tCurIndex};
        				Shunzi[tLianStart["start"]] = tLian;
        			else
        				table.insert(Shunzi[tLianStart["start"]], tCurIndex);
				end

				tLianStart["pre"] = tCurCard;
			end
		end
		tPreCard["index"] = tCurIndex;
		tPreCard["card"] = tCurCard;
	end
end

-- 判断顺子等级
function shunziLevel(shunziCard)
	local tCardLevel = {};

	local tSize = 5;
	local tPreColor = 0;
	local tColorFlag = 0;
	for ic, vc in pairs(shunziCard) do
		local tCurColor = colorCard(vc);
		if tPreColor == 0 then
			tPreColor = tCurColor;
			tColorFlag = 1;
		else
			if tPreColor ~= tCurColor then
				tColorFlag = 0;

				local tDuizi = Duizi[ALLCard[vc]];
				if tDuizi ~= nil then
					for id, vd in pairs(tDuizi) do
						tCurColor = colorCard(vd);
						if tPreColor == tCurColor then
							shunziCard[ic] = vd;
							tColorFlag = 1;
							break;
						end
					end
				end
			end
		end
		
		if tColorFlag == 0 then
			break;
		end
	end
	
	if tColorFlag == 1 then
		if ALLCard[shunziCard[tSize]] == 14 then
			tCardLevel["Level"] = 1;
		else
			tCardLevel["Level"] = 2;
		end
	else
		tCardLevel["Level"] = 6;
	end
	tCardLevel["Card"] = shunziCard;

	return tCardLevel;
end

-- 相同牌等级,四张,三张,对子
function duiziLevel()
	local tCardLevel = {["Level"] = 0, ["Card"] = {}};

	local sizhang = {};
	local sanzhang = {};
	local liangzhang = {};
	for i, v in pairs(Duizi) do
		local tSize = #v;
		if tSize == 4 then
			sizhang[1] = v;
		elseif tSize == 3 then
			table.insert(sanzhang, v);
		else
			table.insert(liangzhang, v);
		end
	end

	local tSiSize = #sizhang;
	local tSanSize = #sanzhang;
	local tLiangSize = #liangzhang;
	
	if tSiSize ~= 0 then
		tCardLevel["Level"] = 3;
		tCardLevel["Card"] = sizhang[1];
	elseif tSanSize ~= 0 then
		if tSanSize > 1 then
			tCardLevel["Level"] = 4;
			for i, v in pairs(sanzhang) do
				for ii, vv in pairs(v) do
					if (i == 1 and ii ~= 1) or i > 1 then
						table.insert(tCardLevel["Card"] , vv);
					end
				end
			end
		elseif tLiangSize > 0 then
			tCardLevel["Level"] = 4;
			tCardLevel["Card"] = {sanzhang[tSanSize][1], sanzhang[tSanSize][2], sanzhang[tSanSize][3], liangzhang[tLiangSize][1], liangzhang[tLiangSize][2]};
		else
			tCardLevel["Level"] = 7;
			tCardLevel["Card"] = {sanzhang[tSanSize][1], sanzhang[tSanSize][2], sanzhang[tSanSize][3]}
		end
	elseif tLiangSize == 1 then
		tCardLevel["Level"] = 9;
		tCardLevel["Card"] = liangzhang[tLiangSize];
	elseif tLiangSize > 1 then
		tCardLevel["Level"] = 8;
		tCardLevel["Card"] = {liangzhang[tLiangSize][1], liangzhang[tLiangSize][2], liangzhang[tLiangSize - 1][1], liangzhang[tLiangSize - 1][2]};
	else
		tCardLevel["Level"] = 0;
	end

	return tCardLevel;
end

-- 同花等级
function colorLevel()
	local tCardLevel = {["Level"] = 0};
	for i, v in pairs(ColorPai) do
		local tSize = #v;
		if tSize >= 5 then
			tCardLevel["Level"] = 5;
			tCardLevel["Card"] = {v[tSize], v[tSize -1], v[tSize - 2], v[tSize - 3], v[tSize - 4]};
			break;
		end
	end
	
	return tCardLevel;
end

-- 同等级牌的比较
function checkCardSize(level, cardA, cardB)
	local tLevel = level;
	if tLevel == 2 then
		local tCardA5 = ALLCard[cardA[5]];
		local tCardB5 = ALLCard[cardB[5]];
		if tCardA5 == tCardB5 then
			return 0
		elseif tCardA5 < tCardB5 then
			return -1;
		else
			return 1;
		end
	elseif tLevel == 3 then
		local tCardA3 = ALLCard[cardA[3]];
                local tCardB3 = ALLCard[cardB[3]];
		if tCardA3 == tCardB3 then
			return 0;
		elseif tCardA3 < tCardB3 then
			return -1;
		else
			return 1;
		end
	elseif tLevel == 4 then
		local tCardA3 = ALLCard[cardA[3]];
		local tCardB3 = ALLCard[cardB[3]];
		if tCardA3 == tCardB3 then                              
                        return 0;                                       
                elseif tCardA3 < tCardB3 then
                        return -1;
                else
                        return 1;
                end
	elseif tLevel == 5 then
		local tI = 5;
		while tI > 0 do
			local tCardA = ALLCard[cardA[tI]];
			local tCardB = ALLCard[cardB[tI]];
			if tCardA < tCardB then
				return -1;
			elseif tCardA > tCardB then
				return 1
			end
			tI = tI - 1;
		end
		return 0;
	elseif tLevel == 6 then
		local tCardA5 = ALLCard[cardA[5]];
                local tCardB5 = ALLCard[cardB[5]];
                if tCardA5 == tCardB5 then                              
                        return 0 
                elseif tCardA5 < tCardB5 then                           
                        return -1;                                      
                else
                        return 1;                                       
                end
	elseif tLevel == 7 then
		local tCardA3 = ALLCard[cardA[3]];              
                local tCardB3 = ALLCard[cardB[3]];              
                if tCardA3 == tCardB3 then
                        return 0;
                elseif tCardA3 < tCardB3 then
                        return -1;
                else
                        return 1;
                end
	elseif tLevel == 8 then
		local tI = 5;
		local tWin = {["win"] = 0, ["lose"] = 0};
		while tI > 0 do
                        local tCardA = ALLCard[cardA[tI]];
                        local tCardB = ALLCard[cardB[tI]];
                        if tCardA < tCardB then
                                return -1;
                        elseif tCardA > tCardB then
                                return 1
                        end
                        tI = tI - 1;
                end
		return 0;
	elseif tLevel == 9 then
		local tI = 5;
		local tDuiziA = 0;
		local tDuiziB = 0;
		local tPreCardA = 0;
		local tPreCardB = 0;
		local tDanPaiA = {};
		local tDanPaiB = {};
		while tI > 0 do
			local tCurCardA = ALLCard[cardA[tI]];
			local tCurCardB = ALLCard[cardB[tI]];
			if tPreCardA == tCurCardA then
				tDuiziA = tCurCardA;
				table.remove(tDanPaiA, 5 - tI);
			else
				tPreCardA = tCurCardA;
				table.insert(tDanPaiA, tCurCardA);
			end
			if tPreCardB == tCurCardB then
				tDuiziB = tCurCardB;
				table.remove(tDanPaiB, 5 - tI);
			else
				tPreCardB = tCurCardB;
				table.insert(tDanPaiB, tCurCardB);
			end
			tI = tI - 1;
		end

		if tDuiziA < tDuiziB then
			return -1;
		elseif tDuiziA > tDuiziB then
			return 1;
		else
			tI = 0;
			while tI < 3 do
				tI = tI + 1;
				local tCurCardA = tDanPaiA[tI];
	                        local tCurCardB = tDanPaiB[tI];
				if tCurCardA < tCurCardB then
					return -1;
				elseif tCurCardA > tCurCardB then
					return 1;
				end
			end
			return 0;
		end
	else
		tI = 5;
                while tI > 0 do
			local tCurCardA = ALLCard[cardA[tI]];
                        local tCurCardB = ALLCard[cardB[tI]];
                        if tCurCardA < tCurCardB then
                                return -1;
                        elseif tCurCardA > tCurCardB then
                                return 1;
                        end
                        tI = tI - 1;
                end
                return 0;
	end
end

--
function whatCard(cards)	-- index, index, index
	table.sort(cards);
	screenCard(cards);

	local tMaxLevel = nil;
	for i, v in pairs(Shunzi) do
		local tSize = #v;
		if tSize == 5 then
			local tLevel = shunziLevel(v);
			if tLevel["Level"] ~= 0 and (tMaxLevel == nil or tMaxLevel["Level"] > tLevel["Level"]) then
				tMaxLevel = tLevel;
			end
		elseif tSize > 5 then
			local tIndex = 5;
			while tIndex <= tSize do
				local tShunzi = {v[tIndex - 4], v[tIndex - 3], v[tIndex - 2], v[tIndex - 1] , v[tIndex]};
				local tLevel = shunziLevel(tShunzi);
				if tLevel["Level"] ~= 0 and (tMaxLevel == nil or tMaxLevel["Level"] > tLevel["Level"]) then
					tMaxLevel = tLevel;
				end
				tIndex = tIndex + 1;
			end  
		end
	end

	local tLevel = duiziLevel();
	if tLevel["Level"] ~= 0 and (tMaxLevel == nil or tMaxLevel["Level"] > tLevel["Level"]) then
		tMaxLevel = tLevel;
	end

	tLevel = colorLevel();
	if tLevel["Level"] ~= 0 and (tMaxLevel == nil or tMaxLevel["Level"] > tLevel["Level"]) then
		tMaxLevel = tLevel;
	end

	local tAllSize = #cards;
	if tMaxLevel ~= nil and tMaxLevel["Level"] > 0 then
		local tCount = 0;
		while #tMaxLevel["Card"] < 5 and tCount < tAllSize do
			local tRet = 0;
			local tCard = cards[tAllSize - tCount];
			for i, v in pairs(tMaxLevel["Card"]) do
				if v == tCard then
					tRet = 1;
					break;
				end
			end
			if tRet ~= 1 then
				table.insert(tMaxLevel["Card"], tCard);
			end
			tCount = tCount + 1;
		end
	else
		tMaxLevel = {["Level"] = 10, ["Card"] = {}};
		local tCount = 0;
		while tCount < 5 do
			table.insert(tMaxLevel["Card"], cards[tAllSize - tCount])
			tCount = tCount + 1;
		end
	end

	table.sort(tMaxLevel["Card"]);
	return tMaxLevel;
end

-- 重置
function CardReset()
	Shunzi = {}	      
        Duizi = {}	      
        ColorPai = {}	      
        CardLevel = {
        	["Level"] = 0,
        	["Card"] = {}
	}
end

-- 随机获取几个玩家的牌, 返回牌ALLCard的索引
function RandCard(count)
	local tTotal = 5 + count * 2;
	local tCount = 0;
	local tCards = {};
	while tCount < tTotal do
		local tIndex = math.random(1, 52);
		if tCards[tIndex] == nil then
			tCards[tIndex] = 1;
			tCount = tCount + 1;
		end
	end
	
	return tCards;
end

function GetCards(tableInfo)
	local tCards = RandCard(tableInfo["PlayerCount"]);
	local tCount = 0;
	local tFull = 2;
	local tIndex = 0;
	for i, v in pairs(tCards) do
		tCount = tCount + 1;
		if tCount <= 5 then
			table.insert(tableInfo["DownCards"], i);
		else
			if tFull == 2 then
				tIndex = getNextPlayer(tIndex, tableInfo);
				tFull = 0;
			end
			table.insert(tableInfo["Players"][tIndex]["OwnCard"], i);
			tFull = tFull + 1;
		end
	end
end

function CheckCards(tableInfo)
	local tMaxLevelPlayer = {};		-- [index] = Cards
	local tMaxLevel = 0;

	for i, v in pairs(tableInfo["Players"]) do
		if validPlayer(v) == 1 then
			CardReset();
			local tCards = {};

			for id, vd in pairs(tableInfo["DownCards"]) do
				table.insert(tCards, vd);
			end

			for ip, vp in pairs(v["OwnCard"]) do
				table.insert(tCards, vp);
			end

			local tLevel = whatCard(tCards);
			tableInfo["EndCardInfo"][i] = tLevel;

			if tMaxLevel == 0 then
				tMaxLevelPlayer[i] = tLevel["Card"];
				tMaxLevel = tLevel["Level"];
			elseif tMaxLevel == tLevel["Level"] then
				tMaxLevelPlayer[i] = tLevel["Card"];
			elseif tMaxLevel > tLevel["Level"] then
				tMaxLevelPlayer = {};
				tMaxLevelPlayer[i] = tLevel["Card"];
				tMaxLevel = tLevel["Level"];
			end
		end
	end

	local tMaxCard = nil;
	tableInfo["Wins"] = {};
	for i, v in pairs(tMaxLevelPlayer) do
		if tMaxCard == nil then
			tMaxCard = v;
			tableInfo["Wins"][i] = v;
		else
			local tRet = checkCardSize(tMaxLevel, tMaxCard, v);
			if tRet == -1 then
				tableInfo["Wins"] = {};
				tableInfo["Wins"][i] = v;
				tMaxCard = v;
			elseif tRet == 0 then
				tableInfo["Wins"][i] = v;
			end
		end
	end
end
