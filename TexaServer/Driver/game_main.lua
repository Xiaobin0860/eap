package.path = './?.lua;./scripts/?.lua;./scripts/libs/?.lua;/usr/local/share/lua/5.2/?.lua;/usr/local/share/lua/5.2/socket/?.lua'
math.randomseed(os.time())

require('common')
require('UserEvent')

function SendPkt()
    local pkt = 'test\0test'
    local driver = GetDriver()
    driver:Send(pkt)
end

function TestTimerFunc(table_id)
    print('table ' .. table_id .. ' timer func')
end

function TestIt()
    local driver = GetDriver()
    driver:StartTimer(1, 'TestTimerFunc', 100)
end

function game_main()
end

print('load game_main.lua')
