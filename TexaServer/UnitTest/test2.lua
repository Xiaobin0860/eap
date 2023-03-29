
local protobuf = require "protobuf"

addr = io.open("addressbook.pb","rb")
buffer = addr:read "*a"
addr:close()

protobuf.register(buffer)

local person = {
	name = "Alice",
	id = 123,
	phone = {
		{ number = "123456789" },
		{ number = "87654321" },
	}
}

function TestLuaCodec()
    local buffer = protobuf.encode("tutorial.Person", person)

    local t = protobuf.decode("tutorial.Person", buffer)
    for k,v in pairs(t) do
        if type(k) == "string" then
            print(k,v)
        end
    end
    print(type(t.phone[1].type) .. ' ' .. t.phone[1].type)
    for k,v in pairs(t.phone[1]) do
        print(k,v)
    end
end

TestLuaCodec()

print('\n===================================================\n')

function OnUserData(packet)

    fuck();

    print('test begin, OnUserData')

    local t = protobuf.decode("tutorial.Person", packet)
    
    for k,v in pairs(t) do
        if type(k) == "string" then
            print(k,v)
        end
    end
    print(t.phone[2].type)
    for k,v in pairs(t.phone[1]) do
        print(k,v)
    end
end