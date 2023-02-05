RaiseMulti = {
	[1] = 1, [2] = 1, [3] = 1, [4] = 1,
	[5] = 1,
}

function CheckRaiseMulti(multi)
	return RaiseMulti[multi];
end

CardType = {
	1,		-- 红心
	2,		-- 方块
	3,		-- 黑心
	4		-- 梅花
}

-- 牌等级
CardLevel = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10
}

-- wanjia
PlayerBetTimer = 3500
