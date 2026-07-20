local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local logger = dofile("/mjcore/core/logger.lua")
local logo = dofile("/mjcore/assets/logo.lua")

local monitor, monitorName = ui.findMonitor(config.monitorName)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if not monitor then
    term.setTextColor(colors.red)
    print("M&J Core no encuentra ningun monitor.")
    logger.log("No se encontro monitor", "ERROR")
    return
end

monitor.setTextScale(config.textScale)
monitor.setBackgroundColor(theme.background)
monitor.clear()

local w, h = monitor.getSize()
local logoTop = math.max(2, math.floor(h / 2) - 7)

for i, line in ipairs(logo) do
    ui.center(monitor, logoTop + i - 1, line, i <= 3 and theme.text or theme.accent, theme.background)
end

ui.center(monitor, logoTop + 7, "M&J CORE", theme.accent, theme.background)
ui.center(monitor, logoTop + 9, "FOUNDATION v" .. config.version, theme.muted, theme.background)

local steps = {
    "Cargando nucleo",
    "Cargando aplicaciones",
    "Preparando escritorio",
    "Sistema listo"
}

for i, step in ipairs(steps) do
    ui.center(monitor, logoTop + 12, step .. "...", theme.text, theme.background)
    ui.progress(monitor, math.floor(w * 0.2), logoTop + 14, math.floor(w * 0.6), i, #steps, theme)
    sleep(0.3)
end

logger.log("Arranque completado en " .. monitorName)
shell.run("/mjcore/desktop.lua")
