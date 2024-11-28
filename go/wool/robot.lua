waiting = 320
interval = 1000
def_price = 10

-- running = false
-- xtsz_recog = nil
-- last_clock = nil
-- setting_price = def_price

function isSkipMessage(msg)
    if not running then
        return false
    end

    if msg.Ident == 4627 then
        return true
    end

    if msg.Ident == 3030 then
        return true
    end

    return false
end

delay_list = delay_list or {}
function onUpdate()
    local clock = os.clock()
    for co, timeout in pairs(delay_list) do
        if clock > timeout then
            delay_list[co] = nil
            coroutine.resume(co)
        end
    end

    if xtsz_recog ~= nil and last_clock ~= nil then
        local duration = (clock - last_clock) * 1000
        if duration > interval then
            ClickNpcObject(xtsz_recog)
            last_clock = clock
        end
    end
end

function onSendMessage(msg)
    if msg.Ident == 3030 then
        onSendChatText(msg.Text)
    end

    if not running then
        return
    end
end

function onRecvMessage(msg)
    if not running then
        return
    end

    if msg.Ident == 643 then
        local co = coroutine.create(onShowNpcDialog)
        coroutine.resume(co, msg.Recog, msg.Text)
    end
end

function Delay(mstime)
    local co = coroutine.running()
    delay_list[co] = os.clock() + mstime / 1000
    coroutine.yield()
end

function onSendChatText(content)
    local argv = splitString(content, " ")
    if argv[1] == "start" then
        running = true
        setting_price = tonumber(argv[2]) or def_price
        print("启动脚本，当前设置价格：" .. setting_price .. "万")
        return
    end
    if argv[1] == "stop" then
        running = false
        print("停止脚本")
        return
    end
end

function onShowNpcDialog(recog, content)
    if not string.find(content, "玄坛使者") then
        return
    end

    xtsz_recog = recog
    last_clock = os.clock()

    if string.find(content, "元宝寄售") then
        Delay(waiting)
        TalkWithNpc(recog, "@GoldBuyMenu")
        return
    end

    if string.find(content, "卖家姓名") then
        local list = getGoldBuyList(content)
        if list[1].Price < setting_price then
            Delay(waiting)
            ClickNpcObject(recog)
            return
        end

        Delay(waiting)
        TalkWithNpc(recog, list[1].Link)
        DealWithNpc(recog, list[1].Count)
        return
    end

    if string.find(content, "是否确认") then
        Delay(waiting)
        local link = content:gsub(".*<确认/(.*)>.*<取消/(.*)>", "%1")
        TalkWithNpc(recog, link)
        return
    end

    if string.find(content, "成功购买") then
        print(content)
        Delay(waiting)
        TalkWithNpc(recog, "@exit")
        return
    end

    if string.find(content, "购买失败") then
        print(content)
        Delay(waiting)
        TalkWithNpc(recog, "@exit")
        return
    end
end

function ClickNpcObject(recog)
    local msg = {
        Recog = recog,
        Ident = 1010,
    }
    SendMessage(msg)
end

function TalkWithNpc(recog, option)
    local msg = {
        Recog = recog,
        Ident = 1011,
        Text = option,
    }
    SendMessage(msg)
end

function DealWithNpc(recog, count)
    local msg = {
        Recog = recog,
        Ident = 26769,
        Text = tostring(count),
    }
    SendMessage(msg)
end

function splitString(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function getGoldBuyList(content)
    local list = {}
    local lines = splitString(content, "\\")
    for _, line in pairs(lines) do
        if string.find(line, "购买") then
            local cells = splitString(line, " ")
            local name = cells[1]
            local price = cells[2]:gsub("万", "")
            local count = cells[3]
            local link = cells[4]:gsub("<购买/(@.*)>", "%1")

            local item = {
                Name = name,
                Price = tonumber(price),
                Count = tonumber(count),
                Link = link,
            }
            table.insert(list, item)
        end
    end
    return list
end
