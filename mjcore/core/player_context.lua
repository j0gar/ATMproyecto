local context = {}
local configPath = "/mjcore/config/player_context.lua"
local cache = {}

local defaults = {
    selectionSeconds = 15,
    radius = 4,
    monitors = {}
}

local function loadConfig()
    local ok, cfg = pcall(dofile, configPath)
    if not ok or type(cfg) ~= "table" then cfg = {} end
    for k,v in pairs(defaults) do if cfg[k] == nil then cfg[k] = v end end
    cfg.monitors = cfg.monitors or {}
    return cfg
end

local function hasMethod(name, wanted)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or type(methods) ~= "table" then return false end
    for _, method in ipairs(methods) do if method == wanted then return true end end
    return false
end

local function detectorNames()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if hasMethod(name, "getPlayersInRange") or hasMethod(name, "getPlayersInCoords") then
            result[#result + 1] = name
        end
    end
    table.sort(result)
    return result
end

local function monitorNames()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then result[#result + 1] = name end
    end
    table.sort(result)
    return result
end

local function autoDetector(monitorName)
    local monitors, detectors = monitorNames(), detectorNames()
    if #detectors == 1 then return detectors[1] end
    for index, name in ipairs(monitors) do
        if name == monitorName then return detectors[index] end
    end
    return nil
end

local function normalizePlayers(players)
    local unique, result = {}, {}
    for _, player in ipairs(players or {}) do
        local name = type(player) == "table" and (player.name or player.username) or player
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local key = string.lower(name)
        if key ~= "" and not unique[key] then
            unique[key] = true
            result[#result + 1] = name
        end
    end
    table.sort(result, function(a,b) return string.lower(a) < string.lower(b) end)
    return result
end

local function samePlayers(a, b)
    if #a ~= #b then return false end
    for i=1,#a do if string.lower(a[i]) ~= string.lower(b[i]) then return false end end
    return true
end

local function now()
    if os.epoch then return os.epoch("utc") / 1000 end
    return os.clock()
end

function context.detect(monitorName)
    local cfg = loadConfig()
    local entry = cfg.monitors[monitorName] or {}
    local detectorName = entry.detector or autoDetector(monitorName)
    if not detectorName then return nil, "No hay Player Detector asignado a " .. tostring(monitorName) end
    local detector = peripheral.wrap(detectorName)
    if not detector then return nil, "No se pudo abrir " .. tostring(detectorName) end

    local ok, players
    if type(detector.getPlayersInRange) == "function" then
        ok, players = pcall(detector.getPlayersInRange, tonumber(entry.radius) or tonumber(cfg.radius) or 4)
    elseif type(detector.getPlayersInCoords) == "function" and entry.corner1 and entry.corner2 then
        local a, b = entry.corner1, entry.corner2
        local min = {x=math.min(a.x,b.x), y=math.min(a.y,b.y), z=math.min(a.z,b.z)}
        local max = {x=math.max(a.x,b.x)+1, y=math.max(a.y,b.y)+1, z=math.max(a.z,b.z)+1}
        ok, players = pcall(detector.getPlayersInCoords, min, max)
    else
        return nil, "El detector necesita getPlayersInRange o coordenadas configuradas"
    end
    if not ok then return nil, tostring(players) end
    return normalizePlayers(players), nil, detectorName
end

function context.resolve(monitorName)
    local players, err = context.detect(monitorName)
    if not players then return nil, err end
    if #players == 0 then return nil, "No hay ningun jugador delante del monitor", players end
    if #players == 1 then return players[1], nil, players end

    local selected = cache[monitorName]
    if selected and selected.expires > now() and samePlayers(selected.players, players) then
        return selected.player, nil, players
    end
    return nil, "multiple", players
end

function context.select(monitorName, player, players)
    local cfg = loadConfig()
    cache[monitorName] = {
        player = player,
        players = players or {},
        expires = now() + (tonumber(cfg.selectionSeconds) or 15)
    }
    return player
end

return context
