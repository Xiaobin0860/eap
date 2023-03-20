
local arena = require('TexasArena')

-- test add
local function TestAdd()
    for i = 1, 6 do
        local tbl = {
            index           = i,
            cur_player      = i,
            player_limit    = 6,
            match_fee       = 1000,
            pump            = 100,
            award1          = 4000,
            award2          = 2000,
            award3          = 0,
		}
        arena:AddTable(tbl)
    end
end

TestAdd()
local t = arena:FindTable(6, 1000)
if t then
    print(t.index .. ' ' .. t.cur_player)
end


arena:PlayerEnter(1, 'TEST01', '6, 1000, 100, 4000, 2000, 0')
