local inventory = {}
local storage = dofile("/mjcore/core/storage.lua")

local function displayName(item)
    if item.displayName and item.displayName ~= "" then return item.displayName end
    return tostring(item.name or "desconocido"):gsub("^.-:", ""):gsub("_", " ")
end

function inventory.scan()
    local slots, controllerName = storage.list()
    if not slots then return nil, controllerName end
    local merged, totalItems = {}, 0
    for _, stack in pairs(slots) do
        if stack and stack.name then
            local key = tostring(stack.name) .. "|" .. tostring(stack.nbt or "")
            local entry = merged[key]
            if not entry then
                entry = {key=key,name=stack.name,displayName=displayName(stack),count=0,nbt=stack.nbt,mod=tostring(stack.name):match("^(.-):") or "minecraft"}
                merged[key] = entry
            end
            entry.count = entry.count + (tonumber(stack.count) or 0)
            totalItems = totalItems + (tonumber(stack.count) or 0)
        end
    end
    local items = {}; for _, entry in pairs(merged) do items[#items+1] = entry end
    return {controllerName=controllerName,items=items,totalTypes=#items,totalItems=totalItems}
end
return inventory
