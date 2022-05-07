local function concatenate(a1, a2)
    local result = {}
    for _, v in ipairs(a1) do
        table.insert(result, v)
    end
    for _, v in ipairs(a2) do
        table.insert(result, v)
    end
    return result
end

local _priate = {}

local function strict_read(t, k)
    if _priate[k] == nil then
        error("key not found: " .. k)
    end
    return _priate[k]
end

local function strict_write(t, k, v)
    if v ~= nil and _priate[k] ~= nil then
        error("key already exists: " .. k)
    end
    _priate[k] = v
end

local mt = {
    __index = strict_read,
    __newindex = strict_write
}
local treasure = setmetatable({}, mt)

local Queue = {}
Queue.__index = Queue

function Queue.new()
    return setmetatable({}, Queue)
end

function Queue:add(item)
    table.insert(self, item)
end

function Queue:remove()
    return table.remove(self, 1)
end

local function retry(count, func)
    local ct = 1
    while ct <= count do
        local _, fn_ok, fn_result = coroutine.resume(coroutine.create(func))
        if fn_ok then
            return ct, fn_result
        end
        ct = ct + 1
    end
    return ct
end

return {
    concatenate = concatenate,
    treasure = treasure,
    Queue = Queue,
    retry = retry
}
