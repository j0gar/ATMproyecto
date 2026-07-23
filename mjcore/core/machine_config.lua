local machineConfig = {}
local ROOT = "/mjcore/config/machines"

local function ensureRoot()
    if not fs.exists("/mjcore/config") then fs.makeDir("/mjcore/config") end
    if not fs.exists(ROOT) then fs.makeDir(ROOT) end
end

local function pathFor(id)
    return fs.combine(ROOT, tostring(id) .. ".json")
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local function merge(base, overrides)
    local result = copy(base or {})
    for key, value in pairs(overrides or {}) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = merge(result[key], value)
        else
            result[key] = copy(value)
        end
    end
    return result
end

function machineConfig.load(machine)
    local defaults = machine.defaults or {}
    local path = pathFor(machine.id)
    if not fs.exists(path) then return merge(defaults, {}) end
    local file = fs.open(path, "r")
    if not file then return merge(defaults, {}) end
    local raw = file.readAll(); file.close()
    local parsed = textutils.unserializeJSON(raw)
    if type(parsed) ~= "table" then return merge(defaults, {}) end
    return merge(defaults, parsed)
end

function machineConfig.save(id, values)
    ensureRoot()
    local file = fs.open(pathFor(id), "w")
    if not file then return false, "No se pudo guardar la configuracion" end
    file.write(textutils.serializeJSON(values or {}, true)); file.close()
    return true
end

function machineConfig.set(machine, key, value)
    local values = machineConfig.load(machine)
    values[key] = value
    local ok, err = machineConfig.save(machine.id, values)
    if not ok then return nil, err end
    return values
end

return machineConfig
