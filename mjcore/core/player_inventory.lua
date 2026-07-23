local playerInventory = {}
local node = dofile("/mjcore/core/node.lua")
local storage = dofile("/mjcore/core/storage.lua")

local function hasMethod(name, wanted)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or type(methods) ~= "table" then return false end
    for _, method in ipairs(methods) do if method == wanted then return true end end
    return false
end

local function isManager(name)
    local ok, matches = pcall(peripheral.hasType, name, "inventory_manager")
    return (ok and matches) or (hasMethod(name, "getOwner") and hasMethod(name, "addItemToPlayer"))
end

local function managers()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if isManager(name) then
            local wrapped = peripheral.wrap(name)
            local ok, owner = pcall(wrapped.getOwner)
            if ok and owner and tostring(owner) ~= "" then
                result[string.lower(tostring(owner))] = {name=name, peripheral=wrapped, owner=tostring(owner)}
            end
        end
    end
    return result
end

local function get(player)
    local all = managers()
    local entry = all[string.lower(tostring(player or ""))]
    if entry then return entry end
    local detected = {}
    for _, value in pairs(all) do detected[#detected+1] = value.owner end
    table.sort(detected)
    return nil, "No hay Inventory Manager para " .. tostring(player) .. (#detected > 0 and (". Detectados: " .. table.concat(detected, ", ")) or ".")
end

function playerInventory.getManagers()
    local result = {}
    for key, entry in pairs(managers()) do result[key] = {name=entry.name, owner=entry.owner} end
    return result
end

function playerInventory.deliver(player, itemName, count)
    local entry, err = get(player)
    if not entry then return nil, err end
    count = math.max(1, math.min(64, tonumber(count) or 1))
    local ok, moved = pcall(entry.peripheral.addItemToPlayer, node.inventorySource, {name=itemName, count=count})
    if not ok then return nil, tostring(moved) end
    moved = tonumber(moved) or 0
    if moved <= 0 then return nil, "No se pudo extraer el objeto; revisa inventorySource=" .. tostring(node.inventorySource) end
    return {moved=moved, requested=count, player=entry.owner, item=itemName}
end

function playerInventory.storeKnown(player)
    local entry, err = get(player)
    if not entry then return nil, err end
    local stored, skipped = 0, 0
    local ok, items = pcall(entry.peripheral.getItems)
    if not ok then return nil, tostring(items) end

    for _, item in ipairs(items or {}) do
        local known = storage.contains(item.name, item.nbt)
        if known then
            local moveOk, moved = pcall(entry.peripheral.removeItemFromPlayer, node.inventorySource, {
                name=item.name, fromSlot=item.slot, count=item.count
            })
            if moveOk then stored = stored + (tonumber(moved) or 0) end
        else
            skipped = skipped + (tonumber(item.count) or 0)
        end
    end
    return {stored=stored, skipped=skipped, player=entry.owner}
end

return playerInventory
