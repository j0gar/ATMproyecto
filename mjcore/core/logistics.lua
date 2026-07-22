local logistics = {}
local inventory = dofile("/mjcore/core/inventory.lua")
local node = dofile("/mjcore/core/node.lua")

local function hasMethod(name, wanted)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or type(methods) ~= "table" then return false end
    for _, method in ipairs(methods) do
        if method == wanted then return true end
    end
    return false
end

local function isInventoryManager(name)
    local ok, matches = pcall(peripheral.hasType, name, "inventory_manager")
    if ok and matches then return true end

    -- Fallback para versiones de CC:Tweaked/Advanced Peripherals donde
    -- peripheral.hasType no identifica correctamente el tipo remoto.
    return hasMethod(name, "getOwner") and hasMethod(name, "addItemToPlayer")
end

local function managers()
    local result = {}

    for _, name in ipairs(peripheral.getNames()) do
        if isInventoryManager(name) then
            local p = peripheral.wrap(name)

            if p then
                local okOwner, owner = pcall(function()
                    return p.getOwner()
                end)

                if okOwner and owner ~= nil and tostring(owner) ~= "" then
                    result[string.lower(tostring(owner))] = {
                        name = name,
                        peripheral = p,
                        owner = tostring(owner)
                    }
                end
            end
        end
    end

    return result
end

function logistics.scan()
    return inventory.scan()
end

function logistics.getManagers()
    local found = {}
    for key, entry in pairs(managers()) do
        found[key] = {
            name = entry.name,
            owner = entry.owner
        }
    end
    return found
end

function logistics.deliver(player, itemName, count)
    count = math.max(1, math.min(64, tonumber(count) or 1))

    local playerKey = string.lower(tostring(player or ""))
    local available = managers()
    local entry = available[playerKey]

    if not entry then
        local detected = {}
        for _, managerEntry in pairs(available) do
            detected[#detected + 1] = managerEntry.owner
        end
        table.sort(detected)

        local detail = #detected > 0
            and (" Detectados: " .. table.concat(detected, ", "))
            or " No se detecto ningun Inventory Manager vinculado."

        return nil, "No hay Inventory Manager para " .. tostring(player) .. "." .. detail
    end

    local okSpace, hasSpace = pcall(function()
        return entry.peripheral.isSpaceAvailable()
    end)

    if okSpace and not hasSpace then
        return nil, "Inventario del jugador lleno"
    end

    local ok, moved = pcall(function()
        return entry.peripheral.addItemToPlayer(
            node.inventorySource,
            {name = itemName, count = count}
        )
    end)

    if not ok then
        return nil, tostring(moved)
    end

    moved = tonumber(moved) or 0

    if moved <= 0 then
        return nil,
            "No se pudo extraer el objeto; revisa inventorySource="
            .. tostring(node.inventorySource)
    end

    return {
        moved = moved,
        requested = count,
        player = entry.owner,
        item = itemName
    }
end

return logistics
