local network = {}
local node = dofile("/mjcore/core/node.lua")
local PROTOCOL = "MJCORE/1"

local activeModem = nil
local activeName = nil

local function validWireless(name)
    if not name or not peripheral.isPresent(name) then return nil end

    local wrapped = peripheral.wrap(name)
    if not wrapped or type(wrapped.isWireless) ~= "function" then return nil end

    local ok, wireless = pcall(wrapped.isWireless)
    if not ok or not wireless then return nil end

    return wrapped
end

local function locateModem()
    if activeName then
        local wrapped = validWireless(activeName)
        if wrapped then
            activeModem = wrapped
            return activeModem, activeName
        end
    end

    local preferred = validWireless(node.modemSide)
    if preferred then
        activeModem = preferred
        activeName = node.modemSide
        return activeModem, activeName
    end

    local names = peripheral.getNames()
    table.sort(names)

    for _, name in ipairs(names) do
        local wrapped = validWireless(name)
        if wrapped then
            activeModem = wrapped
            activeName = name
            return activeModem, activeName
        end
    end

    activeModem = nil
    activeName = nil
    return nil, nil
end

function network.open()
    local modem, name = locateModem()
    if not modem then
        return false, "No se encontro ningun modem wireless"
    end

    local ok, err = pcall(function()
        if type(modem.isOpen) ~= "function" or not modem.isOpen(node.channel) then
            modem.open(node.channel)
        end
    end)

    if not ok then
        activeModem = nil
        activeName = nil
        return false, tostring(err)
    end

    return true, name
end

function network.isOpen()
    local modem = locateModem()
    if not modem then return false end
    if type(modem.isOpen) ~= "function" then return true end

    local ok, opened = pcall(modem.isOpen, node.channel)
    return ok and opened == true
end

local function getOpenModem()
    local ok, result = network.open()
    if not ok then return nil, result end
    return activeModem, activeName
end

function network.send(target, kind, payload, requestId)
    local modem, err = getOpenModem()
    if not modem then return false, err end

    local ok, sendErr = pcall(modem.transmit, node.channel, node.channel, {
        protocol = PROTOCOL,
        from = os.getComputerID(),
        to = target,
        kind = kind,
        payload = payload,
        requestId = requestId
    })

    if not ok then
        activeModem = nil
        activeName = nil
        return false, tostring(sendErr)
    end

    return true
end

function network.request(kind, payload, timeout)
    local stamp
    if os.epoch then
        stamp = os.epoch("utc")
    else
        stamp = math.floor(os.clock() * 1000)
    end

    local requestId = table.concat({
        tostring(os.getComputerID()),
        tostring(stamp),
        tostring(math.random(1000, 9999))
    }, ":")

    local ok, err = network.send(node.serverId, kind, payload, requestId)
    if not ok then return nil, err end

    local timer = os.startTimer(timeout or 4)

    while true do
        local event, a, b, c, d = os.pullEvent()

        if event == "timer" and a == timer then
            return nil, "Servidor sin respuesta (ID " .. tostring(node.serverId) .. ")"
        end

        if event == "modem_message" then
            local channel = b
            local message = d

            if channel == node.channel
            and type(message) == "table"
            and message.protocol == PROTOCOL
            and message.to == os.getComputerID()
            and message.requestId == requestId
            and message.kind == "response" then
                if message.payload and message.payload.ok then
                    return message.payload.data
                end

                return nil, message.payload and message.payload.error or "Respuesta invalida"
            end
        end
    end
end

function network.receive()
    local modem, err = getOpenModem()
    if not modem then return nil, err end

    while true do
        local _, _, channel, _, message = os.pullEvent("modem_message")

        if channel == node.channel
        and type(message) == "table"
        and message.protocol == PROTOCOL
        and (message.to == nil or message.to == os.getComputerID()) then
            return message
        end
    end
end

function network.reply(message, ok, dataOrError)
    local payload
    if ok then
        payload = {ok = true, data = dataOrError}
    else
        payload = {ok = false, error = tostring(dataOrError)}
    end

    return network.send(message.from, "response", payload, message.requestId)
end

function network.getModemName()
    local _, name = locateModem()
    return name
end

return network
