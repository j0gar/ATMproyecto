-- Instalador local de M&J Core
-- Ejecutalo despues de copiar la carpeta mjcore y startup.lua al ordenador.

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.cyan)
print("M&J CORE - INSTALADOR")
term.setTextColor(colors.white)

if not fs.exists("/mjcore/boot.lua") then
    term.setTextColor(colors.red)
    print("ERROR: no existe /mjcore/boot.lua")
    print("Copia primero la carpeta mjcore en la raiz.")
    return
end

if fs.exists("/startup.lua") then
    print("startup.lua ya existe.")
    write("Sobrescribirlo? [s/N]: ")
    local answer = read():lower()
    if answer ~= "s" and answer ~= "si" then
        print("Instalacion cancelada.")
        return
    end
end

local startup = [[
local bootPath = "/mjcore/boot.lua"
if not fs.exists(bootPath) then
    term.setTextColor(colors.red)
    print("M&J Core no esta instalado en /mjcore")
    return
end
shell.run(bootPath)
]]

local file = fs.open("/startup.lua", "w")
file.write(startup)
file.close()

term.setTextColor(colors.lime)
print("Instalacion terminada.")
print("Reiniciando...")
sleep(1)
os.reboot()
