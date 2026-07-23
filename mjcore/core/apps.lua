local apps = {}

local function loadUserRegistry()
    local path = "/mjcore/data/apps.json"
    if not fs.exists(path) then return {} end
    local file = fs.open(path, "r")
    local content = file.readAll(); file.close()
    local registry = textutils.unserializeJSON(content)
    return type(registry) == "table" and registry or {}
end

function apps.loadRegistry()
    local builtins = dofile("/mjcore/core/app_registry.lua")
    local merged, order = {}, {}
    for _, entry in ipairs(builtins) do
        merged[entry.id] = entry; order[#order+1] = entry.id
    end
    for _, entry in ipairs(loadUserRegistry()) do
        if entry.id then
            if merged[entry.id] then
                if entry.enabled ~= nil then merged[entry.id].enabled = entry.enabled end
            else
                order[#order+1] = entry.id
                merged[entry.id] = entry
            end
        end
    end
    local result = {}
    for _, id in ipairs(order) do
        local entry = merged[id]
        if entry and entry.enabled ~= false and entry.path and fs.exists(entry.path) then result[#result+1] = entry end
    end
    table.sort(result, function(a,b) return (a.order or 999) < (b.order or 999) end)
    return result
end
return apps
