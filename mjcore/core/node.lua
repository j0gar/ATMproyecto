local path = "/mjcore/data/node.lua"
local defaults = {role="server",modemSide="left",channel=321,serverId=2,player="j0gar_",inventorySource="right",apps=nil}
local ok, cfg = pcall(dofile, path)
if not ok or type(cfg) ~= "table" then cfg = {} end
for k,v in pairs(defaults) do if cfg[k] == nil then cfg[k] = v end end

-- Migracion de compatibilidad: las versiones anteriores guardaban el jugador
-- como "j0gar", pero el Inventory Manager pertenece realmente a "j0gar_".
-- /mjcore/data se conserva al actualizar, por eso no basta con cambiar defaults.
if string.lower(tostring(cfg.player or "")) == "j0gar" then
    cfg.player = "j0gar_"
end

return cfg
