-- M&J Core startup
local bootPath = "/mjcore/boot.lua"

if not fs.exists(bootPath) then
    term.setTextColor(colors.red)
    print("M&J Core no esta instalado en /mjcore")
    print("Copia la carpeta mjcore en la raiz del ordenador.")
    return
end

shell.run(bootPath)
