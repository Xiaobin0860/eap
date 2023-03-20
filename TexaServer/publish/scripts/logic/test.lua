package.path = './?.lua;./scripts/?.lua;./scripts/libs/?.lua'

require("logic.TaxasTable")
require("logic.TaxasCard")
require("logic.TaxasTableManager")

-- #################### unit test by lyl #########################
TaxasTableInfo["Inited"] = 1
TaxasTable["TableInfo"] = TaxasTableInfo
TaxasTable["Players"][1] = {["name"] = "11",}

NextButtonPlayer(TaxasTable)

if TaxasTable["ButtonPlayer"] ~= 1 then
	SDM_Assert();
end

TaxasTableInfo["Inited"] = 0
TaxasTable["TableInfo"] = nil
TaxasTable["Players"][1] = nil
-- #################### end ##########################

-- #################### unit test by lyl #########################
TaxasTableInfo["Inited"] = 1
TaxasTable["TableInfo"] = TaxasTableInfo
TaxasTable["Players"][1] = {["name"] = "11", ["Flod"] = 0, ["InGameing"] = 1}
TaxasTable["Players"][2] = {["name"] = "22", ["Flod"] = 0, ["InGameing"] = 1}
TaxasTable["Players"][4] = {["name"] = "44", ["Flod"] = 0, ["InGameing"] = 1}
TaxasTable["ButtonPlayer"] = 1;
TaxasTable["TableInfo"]["MaxPlayerCount"] = 9;
TaxasTable["SmallPlayer"] = 0
TaxasTable["BigPlayer"] = 0

local tSmall = SmallBlindsPlayer(TaxasTable)
if tSmall ~= 2 then
	SDM_Assert();
end

local tBig = BigBlindsPlayer(TaxasTable)
if tBig ~= 4 then
	SDM_Assert();
end

TaxasTableInfo["Inited"] = 0
TaxasTable["TableInfo"]["MaxPlayerCount"] = 0;
TaxasTable["TableInfo"] = nil
TaxasTable["Players"][1] = nil
TaxasTable["Players"][2] = nil
TaxasTable["Players"][4] = nil
TaxasTable["ButtonPlayer"] = 0;
-- #################### end ##########################

-- #################### unit test by lyl #########################
TaxasTableInfo["Inited"] = 1
TaxasTable["TableInfo"] = TaxasTableInfo
TaxasTable["Players"][1] = {["name"] = "11",}
TaxasTable["Players"][2] = {["name"] = "22",}
TaxasTable["Players"][3] = {["name"] = "33",}
TaxasTable["ButtonPlayer"] = 1;
TaxasTable["TableInfo"]["MaxPlayerCount"] = 9;

local tEmpty= FindEmptyIndex(TaxasTable)
if tEmpty~= 4 then
        SDM_Assert();
end

TaxasTableInfo["Inited"] = 0
TaxasTable["TableInfo"]["MaxPlayerCount"] = 0;
TaxasTable["TableInfo"] = nil
TaxasTable["Players"][1] = nil
TaxasTable["Players"][2] = nil
TaxasTable["Players"][3] = nil
TaxasTable["ButtonPlayer"] = 0;
-- #################### end ##########################

-- #################### unit test by lyl #########################
math.randomseed(os.time())
local tCount = 5
local tCards = RandCard(tCount)
local tSize = 0;
for i, v in pairs(tCards) do
	tSize = tSize + 1;
	print("count : " .. tCount .. ", size : " .. tSize .. ", card : " .. i .. ", " .. v)
end
if tSize ~= (tCount * 2 + 5) then
	SDM_Assert();
end
-- #################### end ##########################

-- #################### unit test by lyl #########################
TaxasTable["PlayerCount"] = 3
TaxasTable["Players"][1] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTable["Players"][2] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTable["Players"][4] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTableInfo["Inited"] = 1
TaxasTableInfo["MaxPlayerCount"] = 9
TaxasTable["TableInfo"] = TaxasTableInfo

GetCards(TaxasTable)
for i, v in pairs(TaxasTable["DownCards"]) do
	print("----" .. v);
end
for i, v in pairs(TaxasTable["Players"]) do
	print("index : " .. i .. ", card1 : " .. v["OwnCard"][1] .. ", card2 : " .. v["OwnCard"][2])
end
-- #################### end ##########################

-- #################### unit test by lyl #########################
TaxasTable["PlayerCount"] = 3
TaxasTable["Players"][1] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTable["Players"][2] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTable["Players"][4] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTable["Players"][5] = { ["OwnCard"] = {}, ["Flod"] = 0, ["InGameing"] = 1 }
TaxasTableInfo["Inited"] = 1
TaxasTableInfo["MaxPlayerCount"] = 9
TaxasTable["TableInfo"] = TaxasTableInfo
TaxasTable["ButtonPlayer"] = 1;

SetCurPlayer(0, TaxasTable)
print("type0 : " .. TaxasTable["CurPlayer"]);
SetCurPlayer(1, TaxasTable)
print("type1 : " .. TaxasTable["CurPlayer"]);
SetCurPlayer(2, TaxasTable)
print("type2 : " .. TaxasTable["CurPlayer"]);
-- #################### end ##########################

--##################################start###
if colorCard(1) ~= 1 then
	SDM_Assert();
end
if colorCard(2) ~= 2 then
	SDM_Assert();
end
if colorCard(3) ~= 3 then
	SDM_Assert();
end
if colorCard(4) ~= 4 then
	SDM_Assert();
end
if colorCard(5) ~= 1 then
	SDM_Assert();
end
if colorCard(6) ~= 2 then
	SDM_Assert();
end
if colorCard(7) ~= 3 then
	SDM_Assert();
end
if colorCard(8) ~= 4 then
	SDM_Assert();
end
--##################################end#####

--###################################start###
local tCards = {1, 2, 3, 4, 5, 6, 7, 9, 10, 17, 21, 25, 29, 33, 37};
screenCard(tCards);
local tCount = 0;
for i, v in pairs(Shunzi) do
	tCount = tCount + 1;
end
if tCount ~= 2 then
	SMD_Assert();
end

tCount = 0;
for i, v in pairs(Duizi) do
	tCount = tCount + 1;
end
if tCount ~= 3 then
	SMD_Assert();
end

tCount = 0;
for i, v in pairs(ColorPai) do
	tCount = tCount + 1;
end
if tCount ~= 4 then
	SMD_Assert();
end

--###################################end####

--#################################start####
local shunzi1 = {1, 5, 9, 13, 17}
local shunzi2 = {1, 6, 9, 13, 17}
local shunzi3 = {33, 37, 41, 45, 49}
local shunzi4 = {33, 37, 41, 46, 49}
local shunzi5 = {9, 14, 17, 21, 25}
Duizi = {[3] = {5, 6}, [13] = {45, 46} }

CardLevel = shunziLevel(shunzi1);
if CardLevel["Level"] ~= 2 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 5 or CardLevel["Card"][3] ~= 9 or CardLevel["Card"][4] ~= 13 or CardLevel["Card"][5] ~= 17 then
	SDM_Assert();
end
CardLevel = shunziLevel(shunzi2);
if CardLevel["Level"] ~= 2 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 5 or CardLevel["Card"][3] ~= 9 or CardLevel["Card"][4] ~= 13 or CardLevel["Card"][5] ~= 17 then
	SDM_Assert();
end
CardLevel = shunziLevel(shunzi3);
if CardLevel["Level"] ~= 1 or CardLevel["Card"][1] ~= 33 or CardLevel["Card"][2] ~= 37 or CardLevel["Card"][3] ~= 41 or CardLevel["Card"][4] ~= 45 or CardLevel["Card"][5] ~= 49 then
	SDM_Assert();
end
CardLevel = shunziLevel(shunzi4);
if CardLevel["Level"] ~= 1 or CardLevel["Card"][1] ~= 33 or CardLevel["Card"][2] ~= 37 or CardLevel["Card"][3] ~= 41 or CardLevel["Card"][4] ~= 45 or CardLevel["Card"][5] ~= 49 then
	SDM_Assert();
end
CardLevel = shunziLevel(shunzi5);
if CardLevel["Level"] ~= 6 or CardLevel["Card"][1] ~= 9 or CardLevel["Card"][2] ~= 14 or CardLevel["Card"][3] ~= 17 or CardLevel["Card"][4] ~= 21 or CardLevel["Card"][5] ~= 25 then
	SDM_Assert();
end

Duizi = {}
--################################end#####

--###############################start###
Duizi = {[2] = {1, 3, 4}, [3] = {5, 6, 7} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 4 or CardLevel["Card"][1] ~= 3 or CardLevel["Card"][2] ~= 4 or CardLevel["Card"][3] ~= 5 or CardLevel["Card"][4] ~= 6 or CardLevel["Card"][5] ~= 7 then
	SMD_Assert();
end

Duizi = {[2] = {1, 3, 4}, [3] = {5, 6}, [4] = {9, 10} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 4 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 3 or CardLevel["Card"][3] ~= 4 or CardLevel["Card"][4] ~= 9 or CardLevel["Card"][5] ~= 10 then
	SMD_Assert();
end

Duizi = {[2] = {1, 3, 4}, [3] = {5, 6} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 4 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 3 or CardLevel["Card"][3] ~= 4 or CardLevel["Card"][4] ~= 5 or CardLevel["Card"][5] ~= 6 then
	SMD_Assert();
end

Duizi = {[2] = {1, 3, 4} };
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 7 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 3 or CardLevel["Card"][3] ~= 4 then
	SMD_Assert();
end

Duizi = {[2] = {1, 3}, [3] = {5, 6}, [4] = {9, 10} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 8 or CardLevel["Card"][1] ~= 9 or CardLevel["Card"][2] ~= 10 or CardLevel["Card"][3] ~= 5 or CardLevel["Card"][4] ~= 6 then
	SMD_Assert();
end
Duizi = {[2] = {1, 3}, [3] = {5, 6} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 8 or CardLevel["Card"][1] ~= 5 or CardLevel["Card"][2] ~= 6 or CardLevel["Card"][3] ~= 1 or CardLevel["Card"][4] ~= 3 then
	SMD_Assert();
end

Duizi = {[2] = {1, 3} }
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 9 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 3 then
	SMD_Assert();
end

Duizi = {}
CardLevel = duiziLevel();
if CardLevel["Level"] ~= 0 then
	SMD_Assert();
end
--###############################end#######

--##############################start#####
ColorPai = {[1] = {2, 3, 5, 7, 8, 9, 22}}
CardLevel = colorLevel();
if CardLevel["Level"] ~= 5 or CardLevel["Card"][1] ~= 22 or CardLevel["Card"][2] ~= 9 or CardLevel["Card"][3] ~= 8 or CardLevel["Card"][4] ~= 7 or CardLevel["Card"][5] ~= 5 then
	SMD_Assert();
end

ColorPai = {[1] = {5, 7, 8, 9, 22}}
CardLevel = colorLevel();
if CardLevel["Level"] ~= 5 or CardLevel["Card"][1] ~= 22 or CardLevel["Card"][2] ~= 9 or CardLevel["Card"][3] ~= 8 or CardLevel["Card"][4] ~= 7 or CardLevel["Card"][5] ~= 5 then
	SMD_Assert();
end

ColorPai = {[1] = {2, 3, 5, 7}}
CardLevel = colorLevel();
if CardLevel["Level"] ~= 0 then
	SMD_Assert();
end
--############################end###########

--###########################start#########
CardReset();
local tCards = {33, 37, 41, 45, 49, 3, 7}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 1 or CardLevel["Card"][1] ~= 33 or CardLevel["Card"][2] ~= 37 or CardLevel["Card"][3] ~= 41 or CardLevel["Card"][4] ~= 45 or CardLevel["Card"][5] ~= 49 then
	SMD_Assert();
end

CardReset()
tCards = {29, 33, 37, 41, 45, 3, 7}
CardLevel = whatCard(tCards);
print("Level " .. CardLevel["Level"])
for i, v in pairs(CardLevel["Card"]) do
	print("Card  " .. v)
end
if CardLevel["Level"] ~= 2 or CardLevel["Card"][1] ~= 29 or CardLevel["Card"][2] ~= 33 or CardLevel["Card"][3] ~= 37 or CardLevel["Card"][4] ~= 41 or CardLevel["Card"][5] ~= 45 then
	SMD_Assert();
end

CardReset()
tCards = {1, 2, 3, 4, 5, 6}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 3 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 2 or CardLevel["Card"][3] ~= 3 or CardLevel["Card"][4] ~= 4 or CardLevel["Card"][5] ~= 6 then
	SMD_Assert();
end

CardReset()
tCards = {1, 2, 3, 5, 6, 10}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 4 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 2 or CardLevel["Card"][3] ~= 3 or CardLevel["Card"][4] ~= 5 or CardLevel["Card"][5] ~= 6 then
	SMD_Assert();
end

CardReset()
tCards = {1, 5, 13, 17, 21, 41, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 5 or CardLevel["Card"][1] ~= 5 or CardLevel["Card"][2] ~= 13 or CardLevel["Card"][3] ~= 17 or CardLevel["Card"][4] ~= 21 or CardLevel["Card"][5] ~= 41 then
	SMD_Assert();
end

CardReset()
tCards = {1, 6, 9, 13, 17, 43, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 6 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 6 or CardLevel["Card"][3] ~= 9 or CardLevel["Card"][4] ~= 13 or CardLevel["Card"][5] ~= 17 then
	SMD_Assert();
end

CardReset()
tCards = {1, 2, 3, 17, 24, 41, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 7 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 2 or CardLevel["Card"][3] ~= 3 or CardLevel["Card"][4] ~= 41 or CardLevel["Card"][5] ~= 48 then
	SMD_Assert();
end

CardReset()
tCards = {1, 2, 13, 16, 21, 41, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 8 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 2 or CardLevel["Card"][3] ~= 13 or CardLevel["Card"][4] ~= 16 or CardLevel["Card"][5] ~= 48 then
	SMD_Assert();
end

CardReset()
tCards = {1, 2, 13, 17, 22, 40, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 9 or CardLevel["Card"][1] ~= 1 or CardLevel["Card"][2] ~= 2 or CardLevel["Card"][3] ~= 22 or CardLevel["Card"][4] ~= 40 or CardLevel["Card"][5] ~= 48 then
	SMD_Assert();
end

CardReset()
tCards = {1, 8, 13, 26, 33, 42, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 10 or CardLevel["Card"][1] ~= 13 or CardLevel["Card"][2] ~= 26 or CardLevel["Card"][3] ~= 33 or CardLevel["Card"][4] ~= 42 or CardLevel["Card"][5] ~= 48 then
	SMD_Assert();
end

CardReset()
tCards = {1, 8, 13, 36, 40, 44, 48}
CardLevel = whatCard(tCards);
if CardLevel["Level"] ~= 5 or CardLevel["Card"][1] ~= 8 or CardLevel["Card"][2] ~= 36 or CardLevel["Card"][3] ~= 40 or CardLevel["Card"][4] ~= 44 or CardLevel["Card"][5] ~= 48 then
	SMD_Assert();
end

CardReset();
-- ##########################end############

-- ##################################start########
-- 同花
TaxasTable["Players"] = {
	[1] = {["OwnCard"] = {1, 8} },
	[2] = {["OwnCard"] = {1, 2} },
	[3] = {["OwnCard"] = {1, 2} }
}
TaxasTable["DownCards"] = {13, 36, 40, 44, 48}
CheckCards(TaxasTable);
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] ~= nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 8 or TaxasTable["Wins"][1][2] ~= 36 or TaxasTable["Wins"][1][3] ~= 40 or TaxasTable["Wins"][1][4] ~= 44 or TaxasTable["Wins"][1][5] ~= 48 then
	SMD_Assert();
end

TaxasTable["Players"] = {
	[1] = {["OwnCard"] = {22, 26} },
	[2] = {["OwnCard"] = {2, 6} },
	[3] = {["OwnCard"] = {1, 2} }
}
TaxasTable["DownCards"] = {10, 14, 18, 44, 48}
CheckCards(TaxasTable);
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] ~= nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 10 or TaxasTable["Wins"][1][2] ~= 14 or TaxasTable["Wins"][1][3] ~= 18 or TaxasTable["Wins"][1][4] ~= 22 or TaxasTable["Wins"][1][5] ~= 26 then
	SMD_Assert();
end

TaxasTable["Players"] = {                                               
        [1] = {["OwnCard"] = {22, 34} },                                
        [2] = {["OwnCard"] = {2, 30} },                                  
        [3] = {["OwnCard"] = {1, 2} }                                   
}                                                                       
TaxasTable["DownCards"] = {10, 14, 18, 44, 48}                          
CheckCards(TaxasTable);                                                 
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] ~= nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 10 or TaxasTable["Wins"][1][2] ~= 14 or TaxasTable["Wins"][1][3] ~= 18 or TaxasTable["Wins"][1][4] ~= 22 or TaxasTable["Wins"][1][5] ~= 34 then                  
        SMD_Assert();
end

TaxasTable["Players"] = {                                               
        [1] = {["OwnCard"] = {21, 27} },
 	[2] = {["OwnCard"] = {23, 28} },
	[3] = {["OwnCard"] = {1, 2} }
}                                                                       
TaxasTable["DownCards"] = {10, 14, 18, 44, 48}                          
CheckCards(TaxasTable);                                                 
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] == nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 10 or TaxasTable["Wins"][1][2] ~= 14 or TaxasTable["Wins"][1][3] ~= 18 or TaxasTable["Wins"][1][4] ~= 21 or TaxasTable["Wins"][1][5] ~= 27 then                  
        SMD_Assert();
end

TaxasTable["Players"] = {                                               
        [1] = {["OwnCard"] = {22, 26} },                                
        [2] = {["OwnCard"] = {23, 28} },                                  
        [3] = {["OwnCard"] = {1, 2} }                                   
}                                                                       
TaxasTable["DownCards"] = {10, 11, 14, 16, 5}                          
CheckCards(TaxasTable);                                                 
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] == nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 10 or TaxasTable["Wins"][1][2] ~= 11 or TaxasTable["Wins"][1][3] ~= 14 or TaxasTable["Wins"][1][4] ~= 16 or TaxasTable["Wins"][1][5] ~= 26 then                  
        SMD_Assert();
end

TaxasTable["Players"] = {                                               
        [1] = {["OwnCard"] = {29, 35} },                                
        [2] = {["OwnCard"] = {3, 6} },                                  
        [3] = {["OwnCard"] = {1, 7} }                                   
}                                                                       
TaxasTable["DownCards"] = {15, 20, 23, 43, 44}                          
CheckCards(TaxasTable);                                                 
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] ~= nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 23 or TaxasTable["Wins"][1][2] ~= 29 or TaxasTable["Wins"][1][3] ~= 35 or TaxasTable["Wins"][1][4] ~= 43 or TaxasTable["Wins"][1][5] ~= 44 then                  
        SMD_Assert();
end

TaxasTable["Players"] = {                        
        [1] = {["OwnCard"] = {29, 52} },                                
        [2] = {["OwnCard"] = {3, 6} },        
        [3] = {["OwnCard"] = {1, 7} }   
}                                                          
TaxasTable["DownCards"] = {15, 20, 23, 40, 44}                          
CheckCards(TaxasTable);                                    
if TaxasTable["Wins"][1] == nil or TaxasTable["Wins"][2] ~= nil or TaxasTable["Wins"][3] ~= nil or TaxasTable["Wins"][1][1] ~= 23 or TaxasTable["Wins"][1][2] ~= 29 or TaxasTable["Wins"][1][3] ~= 40 or TaxasTable["Wins"][1][4] ~= 44 or TaxasTable["Wins"][1][5] ~= 52 then                  
        SMD_Assert();
end

-- ##################################end##########

--################################################start

local tRet = PlayerEnterTable(10, 1, "")
local tTable = GetTableByTableId(1)

if tRet ~= 0 or tTable["Players"][1] == nil then
	print("errno : " .. tRet);
	SMD_Assert()
end
tRet = PlayerEnterTable(11, 1, "")
if tRet ~= 0 or tTable["Players"][2] == nil then
	print("errno : " .. tRet);
	SMD_Assert()
end
tRet = PlayerEnterTable(12, 1, "")
if tRet ~= 0 or tTable["Players"][3] == nil then
	print("errno : " .. tRet);
	SMD_Assert()
end
StartTable(tTable)
--printTable(tTable)

if tTable["Gameing"] ~= 1 or tTable["PlayerCount"] ~= 3 or tTable["ButtonPlayer"] ~= 1 or tTable["SmallPlayer"] ~= 2 or tTable["BigPlayer"] ~= 3 or tTable["CurPlayer"] ~= 1 or tTable["CurMaxBet"] ~= 200 or tTable["Pot"] ~= 300 or tTable["CurPlayer"] ~= 1 then
	SMD_Assert();
end

OnCall(10, tTable);
printTable(tTable);
OnCall(11, tTable);
--printTable(tTable);
OnCall(12, tTable);
--printTable(tTable);

OnCall(11, tTable);
--printTable(tTable);
OnRaise(12, 2, tTable);
--printTable(tTable);
OnCall(10, tTable);
--printTable(tTable);
OnCall(11, tTable);
--printTable(tTable);
OnCall(12, tTable);
--printTable(tTable);
OnCall(10, tTable);
--printTable(tTable);

OnRaise(11, 1, tTable);
--printTable(tTable);
OnCall(12, tTable);
--printTable(tTable);
OnCall(10, tTable);
printTable(tTable);

--###############################################end##

-- ###################################start#########
--EnterTable(10, 1, "")
--local tTable = TaxasTableManager[1];
--if tTable["PlayerCount"] ~= 1 then
--	SMD_Assert();
--end
--if tTable["Players"][1]["Uid"] ~= 10 then
--	SMD_Assert();
--end
--
--LeaveOutTable(10, 1)
--if tTable["PlayerCount"] ~= 0 then
--	SMD_Assert();
--end
--if tTable["Players"][1] ~= nil then
--	SMD_Assert();
--end

-- ###################################end##########
