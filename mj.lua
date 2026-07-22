local args = {...}
local command = (args[1] or "help"):lower()

local function help()
    print("M&J Core")
    print("")
    print("mj start     Inicia el sistema")
    print("mj update    Busca e instala actualizaciones")
    print("mj version   Muestra la version instalada")
    print("mj logs      Muestra el registro del sistema")
    print("mj setup server|terminal [lado] [jugador] [serverId] [origen]")
    print("mj help      Muestra esta ayuda")
end

if command == "start" then
    shell.run("/mjcore/boot.lua")

elseif command == "update" then
    local updater = dofile("/mjcore/core/updater.lua")
    updater.runInteractive()

elseif command == "setup" then
    local role=(args[2] or ""):lower()
    if role~="server" and role~="terminal" then printError("Uso: mj setup server|terminal [lado] [jugador] [serverId] [origen]"); return end
    local cfg={role=role,modemSide=args[3] or "left",channel=321,serverId=tonumber(args[5]) or 2,player=args[4] or "j0gar",inventorySource=args[6] or "right",apps=role=="terminal" and {"inventory","todo"} or nil}
    local f=fs.open("/mjcore/data/node.lua","w"); f.write("return "..textutils.serialize(cfg)); f.close()
    print("Nodo configurado como "..role..". Reinicia con reboot.")

elseif command == "version" then
    local config = dofile("/mjcore/core/config.lua")
    print("M&J Core " .. tostring(config.version))
    print("Logistics Network")

elseif command == "logs" then
    if fs.exists("/mjcore/logs/system.log") then
        shell.run("type", "/mjcore/logs/system.log")
    else
        print("Todavia no hay registros.")
    end

else
    help()
end
