
-- 竞技场
--[[

    客户端不需要知道所有的竞技场房间信息，所以这个可以由脚本直接管理
    参赛费作为index管理房间，用户请求进入时，根据他请求的index来查找合适的房间

]]

local arena = arena or {}

arena.table_index = 1

function trim(s)
	return s:find('^%s*$') and '' or s:match('^%s*(.*%S)')
end

function string:split(splitter)
    local result = {}
    local start = 1
    local str_start, str_end = self:find(splitter, start)
    while str_start do
        table.insert(result, trim(self:sub(start, str_start - 1)))
        start = str_end + 1
        str_start, str_end = self:find(splitter, start)
    end
    table.insert(result, trim(self:sub(start)))
    return result
end

----------------------------------------------------------------------
-- Arena Table Management

function arena:AddTable(tbl)
    local table_list = self[tbl.match_fee]
    if not table_list then
        table_list = {}
        self[tbl.match_fee] = table_list
    end

    self.table_index = self.table_index + 1
    table.insert(table_list, tbl)
end

function arena:FindTable(player_limit, match_fee)
    local table_list = self[match_fee]
    if not table_list or #table_list == 0 then
        return nil
    end

    table.sort(table_list, function (lhs, rhs)
        return lhs.cur_player > rhs.cur_player
    end)

    for _, v in pairs(table_list) do
        if v.cur_player < player_limit then
            return v
        end
    end
    return nil
end

----------------------------------------------------------------------
-- User Interface

-- desc is: player_limit, match_fee, pump, award1, award2, award3
function arena:PlayerEnter(conn_id, user_id, desc)
    local table_desc = desc:split(',')
    if #table_desc < 6 then
        return -1
    end

    local tbl = self:FindTable(table_desc[1], table_desc[2])
    if not tbl then
        tbl = {
            index           = self.table_index,
            cur_player      = 0,

            player_limit    = table_desc[1],
            match_fee       = table_desc[2],
            pump            = table_desc[3],
            award1          = table_desc[4],
            award2          = table_desc[5],
            award3          = table_desc[6],
        }
        self:AddTable(tbl)
    end

    return tbl.index
end

return arena
