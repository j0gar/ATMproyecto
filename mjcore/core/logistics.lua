-- Fachada de compatibilidad: la v0.8.x usaba logistics para inventario y entregas.
local inventory = dofile("/mjcore/core/inventory.lua")
local players = dofile("/mjcore/core/player_inventory.lua")
return {
    scan = inventory.scan,
    getManagers = players.getManagers,
    deliver = players.deliver,
    storeKnown = players.storeKnown
}
