local path = "/mjcore/data/node.lua"
local defaults = {role="server",modemSide="left",channel=321,serverId=2,player="j0gar",inventorySource="right",apps=nil}
local ok, cfg = pcall(dofile, path)
if not ok or type(cfg) ~= "table" then cfg = {} end
for k,v in pairs(defaults) do if cfg[k] == nil then cfg[k] = v end end
return cfg
