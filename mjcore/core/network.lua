local network = {}
local node = dofile("/mjcore/core/node.lua")
local PROTOCOL = "MJCORE/1"

local cachedModem = nil
local cachedName = nil

local function isWirelessModem(name)
    if not name or not peripheral.isPresent(name) then return false end
    local wrapped = peripheral.wrap(name)
    if not wrapped or type(wrapped.isWireless) ~= "function" then return false end
    local ok, wireless = pcall(wrapped.isWireless)
    return ok and wireless == true
end

local function findWirelessModem()
    if cachedModem and cachedName and peripheral.isPresent(cachedName) then
        return cachedModem, cachedName
    end
    if isWirelessModem(node.modemSide) then
        cachedName = node.modemSide
        cachedModem = peripheral.wrap(cachedName)
        return cachedModem, cachedName
    end
    local names = peripheral.getNames()
    table.sort(names)
    for _, name in ipairs(names) do
        if isWirelessModem(name) then
            cachedName = name
            cachedModem = peripheral.wrap(name)
            return cachedModem, cachedName
        end
    end
    return nil, nil
end

function network.open()
    local modem, name = findWirelessModem()
    if not modem then return false, "No se ha encontrado ningun modem wireless" end
    if not modem.isOpen(node.channel) then modem.open(node.channel) end
    return true, name
end

local function modem()
    local ok, result = network.open()
    if not ok then return nil, result end
    return cachedModem
end

function network.send(target, kind, payload, requestId)
    local m, err = modem()
    if not m then return false, err end
    m.transmit(node.channel, node.channel, {
        protocol = PROTOCOL,
        from = os.getComputerID(),
        to = target,
        kind = kind,
        payload = payload,
        requestId = requestId
    })
    return true
end

function network.request(kind, payload, timeout)
    local requestId = tostring(os.getComputerID()) .. ":" .. tostring(os.epoch and os.epoch("utc") or os.clock()) .. ":" .. tostring(math.random(1000, 9999))
    local ok, err = network.send(node.serverId, kind, payload, requestId)
    if not ok then return nil, err end
    local timer = os.startTimer(timeout or 4)
    while true do
        local event, a, b, c, d = os.pullEvent()
        if event == "timer" and a == timer then return nil, "Servidor sin respuesta" end
        if event == "modem_message" then
            local msg = d
            if type(msg) == "table"
            and msg.protocol == PROTOCOL
            and msg.to == os.getComputerID()
            and msg.requestId == requestId
            and msg.kind == "response" then
                if msg.payload and msg.payload.ok then return msg.payload.data end
                return nil, msg.payload and msg.payload.error or "Respuesta invalida"
            end
        end
    end
end

function network.receive()
    local m, err = modem()
    if not m then return nil, err end
    while true do
        local _, _, _, _, msg = os.pullEvent("modem_message")
        if type(msg) == "table"
        and msg.protocol == PROTOCOL
        and (msg.to == nil or msg.to == os.getComputerID()) then
            return msg
        end
    end
end

function network.reply(msg, ok, dataOrError)
    return network.send(msg.from, "response", ok and {ok = true, data = dataOrError} or {ok = false, error = tostring(dataOrError)}, msg.requestId)
end

return network
