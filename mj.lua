local args = {...}
local command = (args[1] or "help"):lower()

local function help()
    print("M&J Core")
    print("")
    print("mj start     Inicia el sistema")
    print("mj update    Busca e instala actualizaciones")
    print("mj version   Muestra la version instalada")
    print("mj logs      Muestra el registro del sistema")
    print("mj help      Muestra esta ayuda")
end

if command == "start" then
    shell.run("/mjcore/boot.lua")

elseif command == "update" then
    local updater = dofile("/mjcore/core/updater.lua")
    updater.runInteractive()

elseif command == "version" then
    local config = dofile("/mjcore/core/config.lua")
    print("M&J Core " .. tostring(config.version))
    print("Foundation")

elseif command == "logs" then
    if fs.exists("/mjcore/logs/system.log") then
        shell.run("type", "/mjcore/logs/system.log")
    else
        print("Todavia no hay registros.")
    end

else
    help()
end
