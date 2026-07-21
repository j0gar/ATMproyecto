local icons = {}
local cache = {}
local base = "/mjcore/assets/icons/"

function icons.get(name)
    name = tostring(name or "")
    if cache[name] then return cache[name] end
    local path = base .. name .. ".lua"
    if not fs.exists(path) then return nil end
    local ok, data = pcall(dofile, path)
    if ok and type(data) == "table" then cache[name] = data return data end
    return nil
end

return icons
