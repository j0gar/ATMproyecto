local apps = {}

function apps.loadRegistry()
    local path = "/mjcore/data/apps.json"
    if not fs.exists(path) then
        return {}
    end

    local file = fs.open(path, "r")
    local content = file.readAll()
    file.close()

    local registry = textutils.unserializeJSON(content)
    if type(registry) ~= "table" then
        return {}
    end

    local result = {}

    for _, entry in ipairs(registry) do
        if entry.enabled ~= false and entry.path and fs.exists(entry.path) then
            table.insert(result, entry)
        end
    end

    table.sort(result, function(a, b)
        return (a.order or 999) < (b.order or 999)
    end)

    return result
end

return apps
