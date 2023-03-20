
function table_maxn(t)
    local max_k = 0
    for k, _ in pairs(t) do
        if type(k) == 'number' then
            if k > max_k then
                max_k = k
            end
        end
    end
    return max_k
end

function table_size(t)
	local size = 0
	for k, _ in pairs(t) do
		if type(k) == 'number' then
			size = size + 1;
		end
	end
	return size;
end

function hex_dump(buf)
    local hex = ''
    for byte = 1, #buf, 16 do
        local chunk = buf:sub(byte, byte + 15)
        hex = hex .. string.format('%08X  ',byte - 1)
        chunk:gsub('.', function(c)
            hex = hex .. string.format('%02X ',string.byte(c))
        end)
        hex = hex .. string.rep(' ', 3 * (16 - #chunk)) .. ' ' .. chunk:gsub('%c', '.') .. '\n'
    end
    print(hex)
end

function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}

	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end

		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end

	return nSplitArray
end
