local logistics = {}
local inventory = dofile("/mjcore/core/inventory.lua")
local node = dofile("/mjcore/core/node.lua")

local function managers()
    local result = {}
    for _,name in ipairs(peripheral.getNames()) do
        local p = peripheral.wrap(name)
        if p and type(p.getOwner)=="function" and type(p.addItemToPlayer)=="function" then
            local ok, owner = pcall(p.getOwner)
            if ok and owner then result[string.lower(tostring(owner))] = {name=name,peripheral=p,owner=tostring(owner)} end
        end
    end
    return result
end

function logistics.scan() return inventory.scan() end

function logistics.deliver(player, itemName, count)
    count = math.max(1, math.min(64, tonumber(count) or 1))
    local entry = managers()[string.lower(tostring(player or ""))]
    if not entry then return nil, "No hay Inventory Manager para " .. tostring(player) end
    local okSpace, hasSpace = pcall(entry.peripheral.isSpaceAvailable)
    if okSpace and not hasSpace then return nil, "Inventario del jugador lleno" end
    local ok, moved = pcall(entry.peripheral.addItemToPlayer, node.inventorySource, {name=itemName,count=count})
    if not ok then return nil, tostring(moved) end
    moved = tonumber(moved) or 0
    if moved <= 0 then return nil, "No se pudo extraer el objeto; revisa inventorySource=" .. tostring(node.inventorySource) end
    return {moved=moved,requested=count,player=entry.owner,item=itemName}
end
return logistics
