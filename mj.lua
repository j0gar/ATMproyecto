local args = {...}
local command = args[1] or "help"

local function help()
    print("M&J Core")
    print("")
    print("mj start     Inicia el sistema")
    print("mj update    Busca e instala actualizaciones")
    print("mj version   Muestra la version instalada")
    print("mj help      Muestra esta ayuda")
end

if command == "start" then
    shell.run("/mjcore/boot.lua")

elseif command == "update" then
    if not fs.exists("/mjcore/core/updater.lua") then
        printError("No existe el actualizador.")
        return
    end

    local updater = dofile("/mjcore/core/updater.lua")
    updater.runInteractive()

elseif command == "version" then
    local config = dofile("/mjcore/core/config.lua")
    print("M&J Core " .. tostring(config.version))

else
    help()
end
