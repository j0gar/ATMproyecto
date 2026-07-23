if _G.MJ_MIA_DETECTOR then
    return _G.MJ_MIA_DETECTOR
end

local DEFAULT_PLAYER_NAME = "MiaWRaW"

local detector = {
    configPath = "/mjcore/data/mia_detector.lua",
    messagesPath = "/mjcore/data/m-Mia.lua",
    config = nil,
    messages = {},
    peripheral = nil,
    peripheralName = nil,
    chatBox = nil,
    inside = false,
    lastInside = false,
    lastCheck = 0,
    lastMessage = nil,
    lastError = nil,
    lastDeliveryMethod = nil,
    initialized = false
}

local function loadLua(path, fallback)
    if not fs.exists(path) then return fallback end
    local ok, value = pcall(dofile, path)
    if not ok or type(value) ~= "table" then return fallback end
    return value
end

local function normalizeBox(c1, c2)
    return {
        x = math.min(tonumber(c1.x) or 0, tonumber(c2.x) or 0),
        y = math.min(tonumber(c1.y) or 0, tonumber(c2.y) or 0),
        z = math.min(tonumber(c1.z) or 0, tonumber(c2.z) or 0)
    }, {
        -- La configuracion usa esquinas inclusivas. Advanced Peripherals
        -- interpreta el segundo punto como exclusivo: [min, max).
        x = math.max(tonumber(c1.x) or 0, tonumber(c2.x) or 0) + 1,
        y = math.max(tonumber(c1.y) or 0, tonumber(c2.y) or 0) + 1,
        z = math.max(tonumber(c1.z) or 0, tonumber(c2.z) or 0) + 1
    }
end

local function findPlayerDetector()
    local found, name = peripheral.find("player_detector")
    if found then return found, name end

    found, name = peripheral.find("playerDetector")
    if found then return found, name end

    for _, peripheralName in ipairs(peripheral.getNames()) do
        local wrapped = peripheral.wrap(peripheralName)
        if wrapped and type(wrapped.getPlayersInCoords) == "function" then
            return wrapped, peripheralName
        end
    end

    return nil, nil
end

local function findChatBox()
    local chat = peripheral.find("chat_box")
    if chat then return chat end

    chat = peripheral.find("chatBox")
    if chat then return chat end

    for _, name in ipairs(peripheral.getNames()) do
        local wrapped = peripheral.wrap(name)
        if wrapped and (type(wrapped.sendMessage) == "function" or type(wrapped.sendMessageToPlayer) == "function") then
            return wrapped
        end
    end

    return nil
end

local function dayNumber(mode)
    if mode == "real" and os.epoch then
        return math.floor(os.epoch("utc") / 86400000)
    end
    return os.day()
end

function detector.reload()
    detector.config = loadLua(detector.configPath, {})

    -- Migra configuraciones antiguas que el instalador conserva entre versiones.
    -- Algunas versiones anteriores guardaban "Mia", un UUID o espacios invisibles.
    local configuredName = tostring(detector.config.playerName or "")
    configuredName = configuredName:gsub("^%s+", ""):gsub("%s+$", "")
    if configuredName == "" or configuredName == "Mia" or configuredName:find("%-", 1, true) then
        configuredName = DEFAULT_PLAYER_NAME
    end
    detector.config.playerName = configuredName

    detector.messages = loadLua(detector.messagesPath, {})
    detector.peripheral, detector.peripheralName = findPlayerDetector()
    detector.chatBox = findChatBox()
    detector.lastError = nil
    detector.initialized = true
end

function detector.getMessage()
    if #detector.messages == 0 then
        return "No hay mensajes configurados", 0
    end

    local day = dayNumber(detector.config.dayMode)
    local index = (day % #detector.messages) + 1
    return detector.messages[index], index
end

function detector.sendDailyMessage()
    local message = detector.getMessage()
    detector.lastMessage = message

    if not detector.chatBox then
        detector.chatBox = findChatBox()
    end

    if not detector.chatBox then
        detector.lastError = "No se ha encontrado Chat Box"
        return false, detector.lastError
    end

    local recipient = tostring(detector.config.playerName or DEFAULT_PLAYER_NAME)
    recipient = recipient:gsub("^%s+", ""):gsub("%s+$", "")
    if recipient == "" then recipient = DEFAULT_PLAYER_NAME end

    local prefix = tostring(detector.config.chatPrefix or "M&J Core")
    local errors = {}

    -- Advanced Peripherals 0.8 / Minecraft 1.21.1.
    -- El destinatario forma parte de options y utf8 permite los mensajes
    -- personalizados con tildes, eñes y signos de apertura.
    if type(detector.chatBox.sendMessage) == "function" then
        local callOk, result, apiError = pcall(
            detector.chatBox.sendMessage,
            message,
            {
                player = recipient,
                prefix = prefix,
                utf8 = true
            }
        )

        if callOk and result == true then
            detector.lastError = nil
            detector.lastDeliveryMethod = "sendMessage(options.player)"
            return true
        end

        errors[#errors + 1] = tostring(apiError or result or "sendMessage rechazado")
    end

    -- Compatibilidad con Advanced Peripherals 0.7 y anteriores.
    if type(detector.chatBox.sendMessageToPlayer) == "function" then
        local callOk, result, apiError = pcall(
            detector.chatBox.sendMessageToPlayer,
            message,
            recipient,
            prefix,
            "[]",
            "&7",
            nil,
            true
        )

        if callOk and result == true then
            detector.lastError = nil
            detector.lastDeliveryMethod = "sendMessageToPlayer"
            return true
        end

        errors[#errors + 1] = tostring(apiError or result or "sendMessageToPlayer rechazado")
    end

    if #errors == 0 then
        errors[1] = "La Chat Box no tiene un metodo compatible"
    end

    detector.lastError = table.concat(errors, " | ")
    return false, detector.lastError
end

function detector.update(force)
    if not detector.initialized then detector.reload() end

    local now = os.clock()
    local interval = tonumber(detector.config.checkSeconds) or 1
    if not force and now - detector.lastCheck < interval then
        return detector.inside
    end
    detector.lastCheck = now

    if not detector.config.enabled then
        detector.inside = false
        detector.lastError = "Detector desactivado en mia_detector.lua"
        return false
    end

    if not detector.peripheral then
        detector.peripheral, detector.peripheralName = findPlayerDetector()
    end

    if not detector.peripheral then
        detector.inside = false
        detector.lastError = "No se ha encontrado Player Detector"
        return false
    end

    local pos1, pos2 = normalizeBox(
        detector.config.corner1 or {},
        detector.config.corner2 or {}
    )

    local recipient = tostring(detector.config.playerName or DEFAULT_PLAYER_NAME)
    recipient = recipient:gsub("^%s+", ""):gsub("%s+$", "")
    if recipient == "" then recipient = DEFAULT_PLAYER_NAME end

    local found = false
    local detectionError = nil

    -- Esta llamada compara el nombre de forma nativa y evita depender del
    -- formato exacto de los elementos devueltos por getPlayersInCoords.
    if type(detector.peripheral.isPlayerInCoords) == "function" then
        local ok, result = pcall(detector.peripheral.isPlayerInCoords, pos1, pos2, recipient)
        if ok then
            found = result == true
        else
            detectionError = tostring(result)
        end
    end

    -- Fallback para versiones donde solo existe getPlayersInCoords.
    if type(detector.peripheral.isPlayerInCoords) ~= "function" or detectionError then
        local ok, players = pcall(detector.peripheral.getPlayersInCoords, pos1, pos2)
        if not ok then
            detector.inside = false
            detector.lastError = tostring(players)
            return false
        end

        local wanted = string.lower(recipient)
        for _, player in ipairs(players or {}) do
            local name = type(player) == "table" and (player.name or player.username) or player
            if name and string.lower(tostring(name)) == wanted then
                found = true
                break
            end
        end
    end

    detector.lastInside = detector.inside
    detector.inside = found
    detector.lastError = nil

    if detector.config.sendOnEntry and detector.inside and not detector.lastInside then
        detector.sendDailyMessage()
    end

    return detector.inside
end

function detector.status()
    if not detector.initialized then detector.reload() end

    local pos1, pos2 = normalizeBox(
        detector.config.corner1 or {},
        detector.config.corner2 or {}
    )

    return {
        enabled = detector.config.enabled == true,
        playerName = detector.config.playerName or DEFAULT_PLAYER_NAME,
        inside = detector.inside,
        peripheralName = detector.peripheralName,
        hasChatBox = detector.chatBox ~= nil,
        message = detector.getMessage(),
        error = detector.lastError,
        deliveryMethod = detector.lastDeliveryMethod,
        corner1 = pos1,
        corner2 = pos2,
        dayMode = detector.config.dayMode or "minecraft"
    }
end

_G.MJ_MIA_DETECTOR = detector
return detector
