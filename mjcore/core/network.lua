local network = {}
local node = dofile("/mjcore/core/node.lua")
local PROTOCOL = "MJCORE/1"

local function modem()
    local m = peripheral.wrap(node.modemSide)
    if not m or type(m.isWireless) ~= "function" or not m.isWireless() then
        return nil, "No hay modem wireless en " .. tostring(node.modemSide)
    end
    m.open(node.channel)
    return m
end

function network.send(target, kind, payload, requestId)
    local m, err = modem(); if not m then return false, err end
    m.transmit(node.channel, node.channel, {protocol=PROTOCOL,from=os.getComputerID(),to=target,kind=kind,payload=payload,requestId=requestId})
    return true
end

function network.request(kind, payload, timeout)
    local requestId = tostring(os.getComputerID()) .. ":" .. tostring(os.epoch and os.epoch("utc") or os.clock()) .. ":" .. tostring(math.random(1000,9999))
    local ok, err = network.send(node.serverId, kind, payload, requestId); if not ok then return nil, err end
    local timer = os.startTimer(timeout or 3)
    while true do
        local e,a,b,c,d = os.pullEvent()
        if e == "timer" and a == timer then return nil, "Servidor sin respuesta" end
        if e == "modem_message" then
            local msg = d
            if type(msg)=="table" and msg.protocol==PROTOCOL and msg.to==os.getComputerID() and msg.requestId==requestId and msg.kind=="response" then
                if msg.payload and msg.payload.ok then return msg.payload.data end
                return nil, msg.payload and msg.payload.error or "Respuesta invalida"
            end
        end
    end
end

function network.receive()
    local m, err = modem(); if not m then return nil, err end
    while true do
        local _,_,_,_,msg = os.pullEvent("modem_message")
        if type(msg)=="table" and msg.protocol==PROTOCOL and (msg.to==nil or msg.to==os.getComputerID()) then return msg end
    end
end

function network.reply(msg, ok, dataOrError)
    return network.send(msg.from, "response", ok and {ok=true,data=dataOrError} or {ok=false,error=tostring(dataOrError)}, msg.requestId)
end
return network
