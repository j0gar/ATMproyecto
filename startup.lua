local bootPath = "/mjcore/boot.lua"

if not fs.exists(bootPath) then
    term.setTextColor(colors.red)
    print("M&J Core no esta instalado correctamente.")
    print("Falta: " .. bootPath)
    return
end

shell.run(bootPath)
